## 
# Manage polls creation within the sharebox site

class PollsController < ApplicationController

  before_action :authenticate_user!
  
  ##
  # check if user has admin rights<br>
  # All the views and features related to polls are destinated only for admins
  def check_admin
    unless current_user.is_admin?
      flash[:notice] = POLLS_MSG["admin_rights_missing"]
      redirect_to root_url
    end
  end
  
  ##
  # this is just a test of a jointure implementation without logic in the model
  def index
    if params[:request]
      results={}
      sql = <<-SQL
        SELECT satisfactions.*,
        users.email as folder_owner_email, users.statut as folder_owner_statut,
        folders.name as folder_name, folders.id as folder_fid, folders.user_id as folder_user_id, folders.lists as folder_lists, folders.poll_id as folder_poll_id  
        FROM satisfactions 
        INNER JOIN folders 
        ON folders.id = satisfactions.folder_id 
        INNER JOIN users 
        ON users.id = folders.user_id 
        WHERE (satisfactions.folder_id > 0 and users.email LIKE '%cerema%');
      SQL
      mysats=Satisfaction.find_by_sql(sql)
      results.merge!("mysats": mysats.as_json)
      render json: results
    else
      unless current_user.belongs_to_team?
        redirect_to root_url
      end
    end
  end

  ##
  # Show the edit form in order for the admin to update existing polls (title, description...)<br>
  # This view allows you to edit a poll. 
  def edit
    check_admin
    @poll = Poll.find_by_id(params[:id])
    unless @poll
      flash[:notice] = POLLS_MSG["inexisting_poll"]
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
      flash[:notice] = POLLS_MSG["same_questions"]
    elsif params[:poll][:description] == ""
      flash[:notice] = POLLS_MSG["missing_required_fields"]
    elsif params[:poll][:name] == ""
      flash[:notice] = POLLS_MSG["missing_required_fields"]
    elsif params[:poll][:open_names] == "" && params[:poll][:closed_names] == ""
      flash[:notice] = POLLS_MSG["missing_required_fields"]
    else
      params[:poll][:closed_names].strip!
      params[:poll][:open_names].strip!
      params[:poll][:closed_names_number]=params[:poll][:closed_names].split(";").length
      params[:poll][:open_names_number]=params[:poll][:open_names].split(";").length
      flash[:notice]= "#{params[:poll][:closed_names_number]} question(s) fermée(s) #{params[:poll][:open_names_number]} question(s) ouverte(s)"
      if @poll.update(poll_params)
        flash[:notice] = "#{flash[:notice]} - #{POLLS_MSG["poll_updated"]}"
      else
        flash[:notice] = "#{flash[:notice]} - mise à jour non effectuée"
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
  # should be recoded (?) to implement the same result as the route http://localhost:3000/satisfactions?poll_id=5&csv=1
  def show
    poll = Poll.find_by_id(params[:id])
    unless poll
      flash[:notice] = POLLS_MSG["inexisting_poll_number"]
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
      flash[:notice] = POLLS_MSG["missing_required_fields"]
    elsif @poll.name == ""
      flash[:notice] = POLLS_MSG["missing_required_fields"]
    elsif @poll.open_names == "" && @poll.closed_names == ""
      flash[:notice] = POLLS_MSG["missing_required_fields"]
    else
      @poll.closed_names_number=@poll.closed_names.split(";").length
      @poll.open_names_number=@poll.open_names.split(";").length
      array = @poll.get_names
      if array.uniq.count != array.size
        flash[:notice] = POLLS_MSG["same_questions"]
      else
        @poll.save
        flash[:notice] = POLLS_MSG["poll_created"]
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
    flash[:notice] = POLLS_MSG["poll_destroyed"]
    redirect_to root_url
  end

  private
  def poll_params
    params.require(:poll).permit(:name, :description, :closed_names, :open_names, :closed_names_number, :open_names_number)
  end
end