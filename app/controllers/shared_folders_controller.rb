## 
# manage folder sharing within the sharebox site

class SharedFoldersController < ApplicationController

  before_action :authenticate_user!
  
  ##
  # Show the list of the shared emails<br>
  # if a user already answered to the satisfaction form, clicking on his email can display his answer<br>
  # If a user did not answered to the form yet :<br>
  # - It's possible to remove the shared, useful if an error has been done when typing his email address<br>
  # - you can send him an email inviting him to express his satisfaction or to access to a shared folder with file(s)<br>
  def show
    # Happens only when a mail is sent 
    if params[:share_email]
      flash[:notice] = SHARED_FOLDERS_MSG["mail_sent_to"] + params[:share_email]
      InformUserJob.perform_now(params[:share_email])
      redirect_to shared_folder_path(params[:id])
    end

    @shared_folders = current_user.shared_folders.where("folder_id = "+params[:id]) 
    @current_folder = current_user.folders.find(params[:id])

    @satisfactions = Satisfaction.where(folder_id: @current_folder.id)
    @poll = Poll.find_by_id(@current_folder.poll_id)
  end
  
  # This method is only used when following the route /complete_suid<br>
  # it does the following tasks :<br>
  # - send to the admin a list with all the unregistered emails which benefited from shared access to a folder<br>
  # - manually lauch the set_admin method (cf user model)<br>
  def complete_suid
    current_user.complete_suid
    if current_user.set_admin
      flash[:notice] = current_user.email + " root/admin"
    end
    redirect_to root_url
  end

  ##
  # Show the shared form<br>
  # When a folder is shared to a user, you must give at least one email address or more but separated by a ","
  def new
    @to_be_shared_folder = Folder.find_by_id(params[:id])
    if !current_user.has_ownership?(@to_be_shared_folder)
      flash[:notice] = SHARED_FOLDERS_MSG["inexisting_folder"]
      redirect_to root_url
    else
      @shared_folder = current_user.shared_folders.new
      @current_folder = @to_be_shared_folder.parent
    end
  end

  ##
  # Saves the shared emails in the database<br>
  # you cannot share to yourself a folder you own<br>
  # the method verify if shared emails are already registered in the database for the specified folder (folder_id)<br>
  # the sharing activity details are emailed to the admin (cf variable admin_mel as declared in the main section of config.yml)<br>
  def create
    flash[:notice]=""
    emails=params[:shared_folder][:share_email]
    if emails == "" 
      flash[:notice]= SHARED_FOLDERS_MSG["email_needed"]
    else
      email_addresses = emails.split(",")
      mel_text=""
      email_addresses.each do |email_address|
        if email_address == current_user.email
          flash[:notice] += SHARED_FOLDERS_MSG["you_are_folder_owner"] + "<br>"
        else
          email_address=email_address.delete(' ')
          @shared_folder = current_user.shared_folders.new(shared_folder_params)
          @shared_folder.share_email = email_address
          # We search if the email exist in the user table
          # if not, we'll have to update the share_user_id field after registration
          share_user = User.find_by_email(email_address)
          @shared_folder.share_user_id = share_user.id if share_user
          exist = current_user.shared_folders.where("share_email = '"+email_address+"' and folder_id = "+params[:shared_folder][:folder_id])
          if exist.length >0
            flash[:notice] += SHARED_FOLDERS_MSG["already_shared_to"].to_s + email_address + "<br>"
          else
            if @shared_folder.save
              a=SHARED_FOLDERS_MSG["shared_to"] + email_address + "<br>"
              flash[:notice]+=a
              mel_text+=a
            else
              flash[:notice]+= SHARED_FOLDERS_MSG["unable_share_for"] + email_address + "<br>"
            end
          end
        end
      end
    end
    # we leave the sharing form (app/views/shared_folders/_form.html.erb)
    # the id of the folder that we just shared is given by : params[:shared_folders][:folder_id]
    @folder = current_user.folders.find(params[:shared_folder][:folder_id])
    # if mel_text exist, then we send the mail
    if mel_text != ""
      entete=SHARED_FOLDERS_MSG["folder"]+params[:shared_folder][:folder_id]
      entete+="<br><b>["+@folder.name.html_safe+"]</b><br>"
      mel_text=entete+mel_text
      InformAdminJob.perform_now(current_user,mel_text)
      # alternative not using jobs
      #UserMailer.inform_admin(current_user,mel_text).deliver_now
    end
    if @folder.parent_id
      redirect_to folder_path(@folder.parent_id)
    else
      redirect_to root_url
    end
  end

  ##
  # Delete specific share(s) within the show view<br>
  # After deletion, we redirect to root view if all shares were deleted
  def destroy
    if !params[:ids]
      flash[:notice] = SHARED_FOLDERS_MSG["no_share_selected"]
    else
      params[:ids].each do |id|
        SharedFolder.find_by_id(id).destroy
      end
      flash[:notice] = SHARED_FOLDERS_MSG["shares_destroyed"]
    end

    if !SharedFolder.find_by_folder_id(params[:id])
      redirect_to root_url
    else
      redirect_to shared_folder_path(params[:id])
    end
  end

  private
    def shared_folder_params
      params.require(:shared_folder).permit(:share_email, :share_user_id, :folder_id, :message)
    end
  
 end