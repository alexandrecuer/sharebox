## 
# Manage polls creation within the sharebox site

class PollsController < ApplicationController

  before_action :authenticate_user!
  
  ##
  # check if user has admin rights<br>
  # All the views and features related to polls are destinated only for admins
  def check_admin
    unless current_user.is_admin?
      flash[:notice] = t('sb.no_permission')
      redirect_to root_url
    end
  end
  
   ##
   # if route is /getpolls return all the polls in the colibri<br>
   # if route is /getpolls?mynums=1 return poll numbers containing satisfactions answers out of the folders/assets system for the current_user
   def getpolls
    if params[:mynums].to_i==1
      poll_ids=current_user.satisfactions.where("folder_id < ?",0).pluck("DISTINCT poll_id")
      render json: poll_ids
    else
      allpolls = Poll.all.order("id DESC")
      render json: allpolls
    end
   end
  
  ##
  # the index route leads to the satisfactions exploitation main dashboard where everything is done with ajax
  def index
    unless current_user.belongs_to_team? || current_user.is_admin?
      redirect_to root_url
    end
  end

  ##
  # Show the edit form in order for the admin to update existing polls (title, description...)<br>
  # This view allows you to edit a poll. 
  def edit
    check_admin
    @poll = Poll.find_by_id(params[:id])
    unless @poll
      flash[:notice] = t('sb.inexisting')
      redirect_to root_url
    end
  end

  ##
  # Saves the changes<br>
  # You can delete or add open & closed questions
  def update
    check_admin
    @poll = Poll.find_by_id(params[:id])
    array = poll_params[:closed_names].split(";") + poll_params[:open_names].split(";")
    if array.uniq.count != array.size
      flash[:notice] = t('sb.same_questions')
    elsif params[:poll][:description] == ""
      flash[:notice] = t('sb.missing_required_fields')
    elsif params[:poll][:name] == ""
      flash[:notice] = t('sb.missing_required_fields')
    elsif params[:poll][:open_names] == "" && params[:poll][:closed_names] == ""
      flash[:notice] = t('sb.missing_required_fields')
    else
      params[:poll][:closed_names].strip!
      params[:poll][:open_names].strip!
      params[:poll][:closed_names_number]=params[:poll][:closed_names].split(";").length
      params[:poll][:open_names_number]=params[:poll][:open_names].split(";").length
      flash[:notice]= "#{params[:poll][:closed_names_number]} #{t('sb.closed_questions')} #{params[:poll][:open_names_number]} #{t('sb.open_questions')}"
      if @poll.update(poll_params)
        flash[:notice] = "#{flash[:notice]} - #{t('sb.updated')}"
      else
        flash[:notice] = "#{flash[:notice]} - #{t('sb.not_updated')}"
      end
    end
    #redirect_to root_url
    render 'edit'
  end

  ##
  # Show the 'new' form in order for the admin to create new polls<br>
  # open & closed questions can be defined, via two different textarea<br>
  # Questions must be separated by ";"
  def new
    check_admin
    @poll = current_user.polls.new
  end
  

  ##
  # not used actually<br>
  # should be recoded (?) to implement the same result as the route http://localhost:3000/satisfactions/run/poll_id?blabla
  def show
    poll = Poll.find_by_id(params[:id])
    unless poll
      flash[:notice] = t('sb.inexisting')
      redirect_to browse_path
    else
      redirect_to root_url
    end
  end

  ##
  # Create the poll <br>
  # possible only if there is a title, a description and at least 1 question (open or closed)<br>
  # duplicate questions will be rejected and the poll creation will fail
  def create
    check_admin
    @poll = current_user.polls.new(poll_params)
    if @poll.description == ""
      flash[:notice] = t('sb.missing_required_fields')
    elsif @poll.name == ""
      flash[:notice] = t('sb.missing_required_fields')
    elsif @poll.open_names == "" && @poll.closed_names == ""
      flash[:notice] = t('sb.missing_required_fields')
    else
      @poll.closed_names_number=@poll.closed_names.split(";").length
      @poll.open_names_number=@poll.open_names.split(";").length
      array = @poll.get_names
      if array.uniq.count != array.size
        flash[:notice] = t('sb.same_questions')
      else
        @poll.save
        flash[:notice] = t('sb.created')
      end
    end
    render 'new'
    #redirect_to root_url
  end

  ##
  # Destroy a poll/survey <br>
  # Every folder related to this poll will be updated (reinitialize poll_id) <br>
  # All satisfaction answers related to the poll will be deleted cause they all belong to a poll
  def destroy
    check_admin
    @poll = Poll.find_by_id(params[:id])
    Folder.where(poll_id: @poll.id).each do |f|
      f.poll_id = nil
      f.save
    end
    @poll.destroy
    flash[:notice] = t('sb.deleted')
    redirect_to root_url
  end

  private
  def poll_params
    params.require(:poll).permit(:name, :description, :closed_names, :open_names, :closed_names_number, :open_names_number)
  end
end