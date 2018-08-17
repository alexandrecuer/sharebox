## 
# manage folder sharing on the sharebox site

class SharedFoldersController < ApplicationController

  before_action :authenticate_user!
  
  ##
  # On this view, there is a table with every emails of the users having access to the folder 
  # if a user already answered to the satisfaction form, his answers can be displayed by clicking on his email
  # If a user did not answered to the form yet :
  # - It is possible to remove shared access from him
  # - It is also possible to send him an email to tell him that he is able to express his satisfaction
  def show
    # Happend only when a mail is sent 
    if params[:share_email]# Happend only when a mail is sent
      flash[:notice] = SHARED_FOLDERS_MSG["mail_sent_to"] + params[:share_email]
      InformUserJob.perform_now(params[:share_email])
      redirect_to shared_folder_path(params[:id])
    end

    @shared_folders = current_user.shared_folders.where("folder_id = "+params[:id]) 
    @current_folder = current_user.folders.find(params[:id])

    @satisfactions = Satisfaction.where(folder_id: @current_folder.id)
    @poll = Poll.find_by_id(@current_folder.poll_id)
  end
  
  # TODO
  # Used to update the database manually when users sign up
  # if a user has been assigned shares before signing up , the corresponding share_user_id in the table shared_folders are empty
  # when creating the user, an after_create is responsible for filing in the share_user_id 
  def complete_suid
    current_user.complete_suid
    if current_user.set_admin
      flash[:notice] = current_user.email + " root/admin"
    end
    redirect_to root_url
  end

  ##
  # Used to share a folder to a user
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
  # When a folder is shared to a user, you must give one email address or more but separated by a ","
  # If you share a folder to a user that already have access on it, it doesn't work 
  # If you share it to yourself, it doesn't work too because sharing a folder means you already have access on it 
  # It is possible to send an email to the admin to report him that a folder is shared (UserMailer.inform_admin)
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
          flash[:notice] = SHARED_FOLDERS_MSG["already_access"]
        else
          email_address=email_address.delete(' ')
          @shared_folder = current_user.shared_folders.new(shared_folder_params)
          @shared_folder.share_email = email_address
          # We search if the email exist in the user table
          # if he is not, we'll have to update the share_user_id field after registration
          share_user = User.find_by_email(email_address)
          @shared_folder.share_user_id = share_user.id if share_user
          exist = current_user.shared_folders.where("share_email = '"+email_address+"' and folder_id = "+params[:shared_folder][:folder_id])
          if exist.length >0
            flash[:notice] = SHARED_FOLDERS_MSG["already_access_for"].to_s + email_address
          else
            if @shared_folder.save
              a="Partage effectué pour l'adresse : " + email_address + "<br>"
              flash[:notice]+=a
              mel_text+=a
            else
              flash[:notice]+= SHARED_FOLDERS_MSG["unable_share_for"] + email_address + "<br>"
            end
          end
        end
      end
      # if mel_text exist, then we send the mail
      if mel_text != ""
        #UserMailer.inform_admin(current_user,mel_text).deliver_now
        mel_text="Partage du répertoire "+params[:shared_folder][:folder_id]+"<br>"+mel_text
        InformAdminJob.perform_now(current_user,mel_text)
      end
    end
    # we leave the sharing form (app/views/shared_folders/_form.html.erb)
    # the id of the folder that we just shared is given by : params[:shared_folders][:folder_id]
    @folder = current_user.folders.find(params[:shared_folder][:folder_id])
    if @folder.parent_id
      redirect_to folder_path(@folder.parent_id)
    else
      redirect_to root_url
    end
  end

  ##
  # We are on the show view 
  # It is possible to delete multiple shares on a folder in the same time
  # After deletion, if there is still shares for the folder, we stay in the same view 
  # If not, we go back to the root view
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