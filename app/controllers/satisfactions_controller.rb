## 
# Manage satisfactions creation within the sharebox site
# A satisfaction is a form intended for the client to express his satisfaction

class SatisfactionsController < ApplicationController

  before_action :authenticate_user!

  ##
  # Show the new form in order for public users to express their satisfaction :
  # - they have a shared access on the folder 
  # - the folder is polled
  # - they have not already answered to the form
  # The form is composed of open and closed questions
  # We answer a closed question with a score of 1 to 4 represented by stars
  # There is a field for each open questions that allow the user to write his answer 
  # Both types of questions can be left blank
  def new
    @current_folder = Folder.find_by_id(params[:id])
    if !@current_folder
      flash[:notice] = SATISFACTIONS_MSG["inexisting_folder"]
      redirect_to root_url
    else
      if current_user.has_ownership?(@current_folder)
        flash[:notice] = SATISFACTIONS_MSG["folder_owner"]
        redirect_to folder_path(@current_folder)
      end
      if !current_user.has_shared_access?(@current_folder)
        flash[:notice] = SATISFACTIONS_MSG["unshared_folder"]
        redirect_to root_url
      end
      if !@current_folder.is_polled?
        flash[:notice] = SATISFACTIONS_MSG["unpolled_folder"]
        redirect_to folder_path(@current_folder)
      end
      if current_user.has_completed_satisfaction?(@current_folder)
        flash[:notice] = SATISFACTIONS_MSG["already_answered"]
        redirect_to folder_path(@current_folder)
      end
      @satisfaction = Satisfaction.new
      @poll = Poll.all.find_by_id(@current_folder.poll_id)
    end
  end
  
  ##
  # Show all existing answers on a specific folder
  # Any user can only check answers on a folder if they have shared access and if the folder is polled
  def show 
    @satisfaction = Satisfaction.find_by_id(params[:id])
    if !@satisfaction
      flash[:notice] = SATISFACTIONS_MSG["inexisting_satisfaction"]
      redirect_to root_url
    else
      @current_folder = Folder.find_by_id(@satisfaction.folder_id)
      if !( current_user.has_shared_access?(@current_folder) || current_user.is_admin? )
        flash[:notice] = SATISFACTIONS_MSG["access_forbidden"]
        redirect_to root_url
      end
      @poll = Poll.all.find_by_id(@current_folder.poll_id)
      render 'new'
    end
  end

  ##
  # Save a satisfaction answer
  def create
    @satisfaction = Satisfaction.new(satisfaction_params)
    @current_folder = Folder.find_by_id(params[:satisfaction][:folder_id])
    @satisfaction.user_id = current_user.id
    if @satisfaction.save
      flash[:notice] = SATISFACTIONS_MSG["satisfaction_created"]
      @poll = Poll.all.find_by_id(@satisfaction.poll_id)
    else
      flash[:notice] = SATISFACTIONS_MSG["satisfaction_error"]
    end
    render 'new'
  end

  ##
  # Destroy a specific satisfaction
  # The show form of the poll_controller include a delete button
  def destroy
    @satisfaction = Satisfaction.find_by_id(params[:id])
    @poll = Poll.find_by_id(@satisfaction.poll_id)
    @satisfaction.destroy
    redirect_to poll_path(@poll)
  end

  private
    def satisfaction_params
      params.require(:satisfaction).permit(:folder_id, :poll_id, :case_number, :closed1, :closed2, :closed3, :closed4, :closed5, :closed6, :closed7, :closed8, :closed9, :closed10, :closed11, :closed12, :closed13, :closed14, :closed15, :closed16, :closed17, :closed18, :closed19, :closed20, :open1, :open2, :open3, :open4, :open5, :open6, :open7, :open8, :open9, :open10, :open11, :open12, :open13, :open14, :open15, :open16, :open17, :open18, :open19, :open20)
    end
end
