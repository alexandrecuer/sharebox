## 
# Manage polls creation within the sharebox site

class PollsController < ApplicationController

  before_action :authenticate_user!, :check_admin

  ##
  # check if user has admin rights<br>
  # All the views and features related to polls are destinated only for admins
  def check_admin
    if !current_user.is_admin?
      flash[:notice] = POLLS_MSG["admin_rights_missing"]
      redirect_to root_url
    end
  end

  ##
  # Show the edit form in order for the admin to update existing polls (title, description...)<br>
  # This view allows you to edit a poll. 
  def edit
    @poll = Poll.find_by_id(params[:id])
    if !@poll
      flash[:notice] = POLLS_MSG["inexisting_poll"]
      redirect_to root_url
    end
  end

  ##
  # Saves the changes<br>
  # You can delete or add open & closed questions
  def update
    @poll = Poll.find_by_id(params[:id])
    array = poll_params[:closed_names].split(";") + poll_params[:open_names].split(";")
    if array.uniq.count != array.size
      flash[:notice] = POLLS_MSG["same_questions"]
    else
      if @poll.update(poll_params)
        flash[:notice] = POLLS_MSG["poll_updated"]
      end
    end
    redirect_to root_url
  end

  ##
  # Show the 'new' form in order for the admin to create new polls<br>
  # open & closed questions can be defined, via two different textarea<br>
  # Questions must be separated by ";"
  def new
    @poll = current_user.polls.new
  end

  ##
  # Show all satisfaction answers related to the poll<br>
  # A csv file containing all the datas can be downloaded 
  def show
    @poll = Poll.find_by_id(params[:id])
    @hash = current_user.get_all_emails

    if !@poll
      flash[:notice] = POLLS_MSG["inexisting_poll_number"]
      redirect_to root_url
    end

    # CSV functionality
    respond_to do |format|
      format.html
      format.csv { send_data @poll.to_csv(@hash), filename: "polls-#{Date.today}.csv" }
    end
  end

  ##
  # Create the poll <br>
  # possible only if there is a title, a description and at least 1 question (open or closed)<br>
  # duplicate questions will be rejected and the poll creation will fail
  def create
    @poll = current_user.polls.new(poll_params)
    if (( @poll.open_names == "" && @poll.closed_names == "" ) || @poll.description == "" || @poll.name == "" )
      flash[:notice] = POLLS_MSG["missing_required_fields"]
    else
      array = @poll.get_names
      if array.uniq.count != array.size
        flash[:notice] = POLLS_MSG["same_questions"]
      else
        @poll.save
        flash[:notice] = POLLS_MSG["poll_created"]
      end
    end
    redirect_to root_url
  end

  ##
  # Destroy a poll/survey <br>
  # Every folder related to this poll will be updated (reinitialize poll_id) <br>
  # All satisfaction answers related to the poll will be deleted.
  def destroy
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