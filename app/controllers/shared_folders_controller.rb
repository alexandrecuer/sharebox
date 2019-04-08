## 
# manage folder sharing within the sharebox site

class SharedFoldersController < ApplicationController

  before_action :authenticate_user!
  
  ##
  # ?id=1 show metadatas for folder 1
  # ?id=1&update_meta=1 update metadatas for folder 1
  # ?update_meta=1 update metadatas for all folders
  def index
    unless current_user.is_admin?
      log="vous n'avez pas les droits suffisants"
    else
      if params[:update_meta]
        all_saved=true
        log="updating metadatas on Colibri....\n"
        unless params[:id]
          folders=Folder.all
          folders.each do |fol|
            a=fol.calc_meta
            fol.lists=a
            puts("****#{a}")
            unless fol.save
              all_saved=false
            else
              log="#{log} -> folder #{fol.id} named (#{fol.name}) metadatas are now #{fol.lists}\n"
            end
          end
          if all_saved 
            log="#{log}So good so far, all folders metadatas should now be up-to-date"
          else
            log="#{log}Something got wrong while updating folders metadatas"
          end
        else
          if f = current_user.folders.find_by_id(params[:id])
            f.lists=f.calc_meta
            if f.save
              log="#{log} -> folder #{f.id} named (#{f.name}) metadatas are now #{f.lists}"
            else 
              log="#{log} -> impossible to update metadatas for folder #{f.id} named #{f.name}"
            end
          else
            log="#{log} -> inexisting folder - cannot go further"
          end
        end
      else
        unless params[:id] 
          log="checking metadatas on all folders...\n"
          folders=Folder.all
          folders.each do |fol|
            log="#{log} -> folder #{fol.id} named (#{fol.name}) metadatas are #{fol.lists}\n"
          end
        else
          unless folder = Folder.find_by_id(params[:id])
            log="inexisting folder\n"
          else
            if folder.lists
              log="checking metadatas on a single folder.....\n"
              log="#{log} -> folder #{folder.id} named (#{folder.name}) metadatas are #{folder.lists} \n"
            else
              log="nothing to show - no metadata - should process to update \n"
            end
          end
        end
      end
    end
    @log=log
  end
  
  ##
  # Show the control panel allowing to manage all share emails associated to a folder<br>
  # Via the control panel, the folder owner can :<br>
  # - display satisfaction answers by clicking on the email of the user who recorded the satisfaction<br>
  # - remove shares one by one, unless a satisfaction answer was recorded on the share<br>
  # - send automatic emails<br>
  # For each share email, the control panel display the number of clicks on the shared assets<br>
  # The form of the user email can be different depending on the 'shared' folder configuration<br>
  # You can have many different folder configurations :<br>
  # - folder with files but without any poll associated > file available type mel<br>
  # - folder with files and with a poll associated > file+satisfaction type mel<br>
  # - folder without files and with a poll associated (TO BAN) > satisfaction type mel<br>
  # - one of the above with satisfaction answer(s) > no email for users who already recorded their satisfaction<br>
  # - folder with or without files, with satisfaction answer(s) and with no poll associated<br>
  # - folder with or without files and with satisfaction answers(s) on a poll which was removed and replaced by another one<br>
  # - folder with or without files and with satisfaction answer(s) on different polls<br>
  # You cannot send email from an empty folder without any poll associated
  def show
    @current_folder = Folder.find_by_id(params[:id])
    unless @current_folder
      flash[:notice] = FOLDERS_MSG["inexisting_folder"]
      redirect_to root_url
    end
    # bof bof un user public peut s'envoyer un fichier
    unless (current_user.is_admin? || current_user.has_shared_access?(@current_folder))
      flash[:notice] = "cette action ne vous est pas autorisée"
      redirect_to root_url
    end
    # Happens only when a mail is sent 
    if params[:share_email]
      nbfiles_in_folder=@current_folder.assets.count
      puts("**************#{nbfiles_in_folder} file(s) in the folder #{params[:id]}");
      unless (nbfiles_in_folder>0 || @current_folder.is_polled?)
        t1 = "Vous ne pouvez pas envoyer de mel !"
        t2 = "D'une part, le répertoire partagé est vide"
        t3 = "D'autre part, le répertoire partagé n'est pas lié à une enquête satisfaction"
        t4 = "Chargez donc un livrable ou associez au répertoire une enquête satisfaction"
        flash[:notice] = "#{t1}<br>#{t2}<br>#{t3}<br>#{t4}"
      else
        flash[:notice] = "#{SHARED_FOLDERS_MSG["mail_sent_to"]} #{params[:share_email]}"
        InformUserJob.perform_now(current_user,params[:share_email],params[:id])
      end
      redirect_to shared_folder_path(params[:id])
    end
    @shared_folders = @current_folder.shared_folders
    @satisfactions = @current_folder.satisfactions
  end
  
  # This method is only used when MANUALLY following the route /complete_suid<br>
  # it does the following tasks :<br>
  # - send to the admin a list with all the unregistered emails which benefited from shared access to a folder<br>
  # - manually launch the set_admin method (cf user model)<br>
  def complete_suid
    current_user.complete_suid
    if current_user.set_admin
      flash[:notice] = "#{current_user.email} root/admin"
    end
    redirect_to root_url
  end

  ##
  # Show the sharing form<br>
  # When a folder is shared to a user, you must give at least one email address or more but separated by a ","
  def new
    unless @to_be_shared_folder = current_user.folders.find_by_id(params[:id])
    #if !current_user.has_ownership?(@to_be_shared_folder)
      flash[:notice] = SHARED_FOLDERS_MSG["inexisting_folder"]
      redirect_to root_url
    else
      @shared_folder = current_user.shared_folders.new
      @current_folder = @to_be_shared_folder.parent
    end
  end
  
  ##
  # get all shares for a given folder
  def getshares
    folder_id=params[:folder_id]  
    shares=SharedFolder.where(folder_id: folder_id)
    render json: shares
  end
  
  ##
  # share a folder through an ajax post
  def share
    emails=params[:share_email].delete(" ")
    folder_id=params[:folder_id]
    results={}
    if emails == ""
      results["success"]=false
      results["message"]=SHARED_FOLDERS_MSG["email_needed"]
    else
      folder = current_user.folders.find_by_id(folder_id)
      unless folder
        results["success"]=false
        result="impossible de continuer\n"
        results["message"]="#{result}ce répertoire n'existe pas ou ne vous appartient pas"
      else
        processed = folder.process_share_emails(emails,current_user)
        results["message"]=processed[:message]
        results["success"]=processed[:saved_shares]
      end
    end
    render json: results
  end

  ##
  # Saves the shared emails in the database<br>
  # you cannot share to yourself a folder you own<br>
  # verify if shared emails are already registered in the database for the specified folder (folder_id)<br>
  # uses for this the process_share_emails method of the folder model 
  # the sharing activity details are emailed to the admin (cf variable admin_mel as declared in the main section of config.yml)<br>
  def create
    emails=params[:shared_folder][:share_email].delete(" ")
    if emails == ""
      flash[:notice]= SHARED_FOLDERS_MSG["email_needed"]
      redirect_to new_share_on_folder_path(params[:shared_folder][:folder_id])
    else
      @folder = current_user.folders.find(params[:shared_folder][:folder_id])
      unless @folder
        flash[:notice]="impossible de continuer<br>ce répertoire n'existe pas ou ne vous appartient pas"
        redirect_to root_url
      else 
        result = @folder.process_share_emails(emails,current_user)
        flash[:notice]=result[:message].gsub(/\n/,"<br/>")
        if result[:saved_shares]
          if @folder.parent_id
            redirect_to folder_path(@folder.parent_id)
          else
            redirect_to root_url
          end
        else
          redirect_to new_share_on_folder_path(params[:shared_folder][:folder_id])
        end
        # if new shares were successfully saved, then we inform the admin
        if result[:saved_shares]
          mel_to_admin = "#{SHARED_FOLDERS_MSG["folder"]} #{params[:shared_folder][:folder_id]}<br>"
          mel_to_admin = "#{mel_to_admin}<b>[#{@folder.name.html_safe}]</b><br>#{flash[:notice]}"
          InformAdminJob.perform_now(current_user,mel_to_admin)
          # alternative not using jobs
          #UserMailer.inform_admin(current_user,mel_to_admin).deliver_now
        end
      end
    end
  end
  
  ##
  # delete a given share
  def deleteshare
    results={}
    folder = current_user.folders.find_by_id(params[:folder_id])
    unless folder
      results["success"]=false
      results["message"] = "ce répertoire n'existe pas ou ne vous appartient pas"
    else
      id=params[:id]
      share=SharedFolder.find_by_id(id)
      unless share
        results["success"]=false
        results["message"]="ce partage n'existe pas"
      else
        if share.destroy
          results["success"]=true
          folder.lists=folder.calc_meta
          unless folder.save
            results["message"]="impossible de mettre à jour les métadonnées"
          else
            results["message"]="partage supprimé"
          end
        else
          results["success"]=false
          results["message"]="impossible de supprimer le partage"
        end
      end
    end
    render json: results
  end

  ##
  # Delete specific share(s) within the show view<br>
  # After deletion, we redirect to root view if all shares were deleted
  def destroy
    folder = Folder.find_by_id(params[:id])
    unless folder
      flash[:notice] = "ce répertoire n'existe pas"
      redirect_to root_url
    end
    unless (current_user.is_admin? || current_user.has_shared_access?(folder))
      flash[:notice] = "cette action ne vous est pas autorisée"
      redirect_to root_url
    end
    unless params[:ids]
      flash[:notice] = SHARED_FOLDERS_MSG["no_share_selected"]
    else
      params[:ids].each do |id|
        SharedFolder.find_by_id(id).destroy
      end
      flash[:notice] = SHARED_FOLDERS_MSG["shares_destroyed"]
      # some shares were deleted - we have to update folder metadatas
      folder.lists=folder.calc_meta
      unless folder.save
        flash[:notice] = "#{flash[:notice]} impossible de mettre à jour les metadonnées du répertoire !!<br>"
      end
    end

    unless SharedFolder.find_by_folder_id(params[:id])
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