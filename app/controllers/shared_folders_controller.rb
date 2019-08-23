## 
# manage folder sharing within the sharebox site<br>
# You can have many different folder configurations :<br>
# - folder with files but without any poll associated > file available type mel<br>
# - folder with files and with a poll associated > file+satisfaction type mel<br>
# - folder without files and with a poll associated (TO BAN) > satisfaction type mel<br>
# - one of the above with satisfaction answer(s) > no email for users who already recorded their satisfaction<br>
# - folder with or without files, with satisfaction answer(s) and with no poll associated<br>
# - folder with or without files and with satisfaction answers(s) on a poll which was removed and replaced by another one<br>
# - folder with or without files and with satisfaction answer(s) on different polls<br>
# You cannot send email from an empty folder without any poll associated<br>
# uses the process_share_emails method of the folder model [To create the shares on the basis of a list of emails]

class SharedFoldersController < ApplicationController

  before_action :authenticate_user!
  
  # uses validations module
  
  ##
  # ?id=1 show metadatas for folder 1
  # ?id=1&update_meta=1 update metadatas for folder 1
  # ?update_meta=1 update metadatas for all folders
  def index
    unless current_user.is_admin?
      log=t('sb.no_permission')
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
  def show
    @current_folder = Folder.find_by_id(params[:id])
    unless @current_folder
      flash[:notice] = t('sb.inexisting_folder')
      redirect_to root_url
    end
    unless (current_user.is_admin? || current_user.has_shared_access?(@current_folder))
      flash[:notice] = t('sb.no_permission')
      redirect_to root_url
    end
    @shared_folders = @current_folder.shared_folders
    @satisfactions = @current_folder.satisfactions
  end
  
  ##
  # contact customer and send a 'client' email<br>
  # uses the email_customer of the folder model<br>
  # The form of the user can be different depending on the 'shared' folder configuration<br>
  # please note it is not possible to send a 'client' email to a TEAM member
  def contact_customer
    results={}
    folder_id=params[:folder_id]
    customer_email=params[:share_email]
    current_folder=current_user.folders.find_by_id(folder_id)
    unless current_folder
      results["success"]=false
      result="#{t('sb.stop')}, #{t('sb.maybe')} : \n"
      results["message"]="#{result}- #{t('sb.inexisting_folder')}\n - #{t('sb.folder_not_for_yu')}"
    else
      puts("customer is #{customer_email}")
      unless Validations.mel_reg_exp.match(customer_email)
        results["success"]=false
        result="#{t('sb.stop')}\n"
        results["message"]="#{result}#{t('sb.no_mel_given')}"
      else
        if ENV['TEAM']
          teamdomain=ENV.fetch('TEAM')
        else
          teamdomain="cerema.fr"
        end
        inteam = customer_email.split("@")[1]==teamdomain
        if inteam
          results["success"]=false
          results["message"]=t('sb.no_client_mel_for_team_member')
        else
          email_to_search=customer_email
          if Rails.configuration.sharebox["downcase_email_search_autocompletion"]
            email_to_search=email_to_seach.downcase
          end
          if share=current_user.shared_folders.find_by_share_email(email_to_search)
            if customer=User.find_by_email(email_to_search)
              if satis=Satisfaction.find_by_folder_id_and_user_id(folder_id, customer.id)
                processed={}
                processed["success"]=false
                processed["message"]="#{t('sb.client_already_answered')}\n #{t('sb.feedback_number')} #{satis.id} "
              else
                processed = current_folder.email_customer(current_user,customer_email,share,customer)
              end
            else
              processed = current_folder.email_customer(current_user,customer_email,share)
            end
            results["success"]=processed["success"]
            results["message"]=processed["message"]
          else
            results["success"]=false
            results["message"]="#{t('sb.folder')} #{t('sb.id')} #{folder_id} \n#{t('sb.no_share_owned_with_email')}"
          end
        end
      end
    end
    render json: results
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
  # DEPRECATED since the new browsing system is active
  # if wish to use anyway, follow route shared_folders/:folder_id/new
  def new
    unless @to_be_shared_folder = current_user.folders.find_by_id(params[:id])
    #if !current_user.has_ownership?(@to_be_shared_folder)
      flash[:notice]="#{t('sb.stop')}, #{t('sb.maybe')} :<br>"
      flash[:notice]="#{flash[:notice]}- #{t('sb.inexisting_folder')}<br> - #{t('sb.folder_not_for_yu')}"
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
      results["message"]=t('sb.no_mel_given')
    else
      folder = current_user.folders.find_by_id(folder_id)
      unless folder
        results["success"]=false
        result="#{t('sb.stop')}, #{t('sb.maybe')} :\n"
        results["message"]="#{result}- #{t('sb.inexisting_folder')}\n - #{t('sb.folder_not_for_yu')}"        
      else
        processed = folder.process_share_emails(emails,current_user)
        results["message"]=processed[:message]
        results["success"]=processed[:saved_shares]
      end
    end
    render json: results
  end

  ##
  # DEPRECATED since the new browsing system is active<br>
  # Saves the shared emails in the database<br>
  # you cannot share with yourself a folder you own<br>
  # verify if shared emails are already registered in the database for the specified folder (folder_id)<br>
  # uses for this the process_share_emails method of the folder model 
  # the sharing activity details are emailed to the admin (cf variable admin_mel as declared in config.yml)<br>
  def create
    emails=params[:shared_folder][:share_email].delete(" ")
    if emails == ""
      flash[:notice]= t('sb.no_mel_given')
      redirect_to new_share_on_folder_path(params[:shared_folder][:folder_id])
    else
      @folder = current_user.folders.find(params[:shared_folder][:folder_id])
      unless @folder
        flash[:notice]="#{t('sb.stop')}, #{t('sb.maybe')} :<br>"
        flash[:notice]="#{flash[:notice]}- #{t('sb.inexisting_folder')}<br> - #{t('sb.folder_not_for_yu')}"
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
          mel_to_admin = "#{t('sb.folder')} #{params[:shared_folder][:folder_id]}<br>"
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
      result="#{t('sb.stop')}, #{t('sb.maybe')} : \n"
      results["message"]="#{result}- #{t('sb.inexisting_folder')}\n - #{t('sb.folder_not_for_yu')}"
    else
      id=params[:id]
      share=SharedFolder.find_by_id(id)
      unless share
        results["success"]=false
        results["message"]="#{t('sb.inexisting')}\n #{t('sb.share_number')} #{id}"
      else
        if share.destroy
          results["success"]=true
          folder.lists=folder.calc_meta
          unless folder.save
            results["message"]="#{t('sb.folder_metas')}\n #{t('sb.not_updated')}"
          else
            results["message"]=t('sb.deleted')
          end
        else
          results["success"]=false
          results["message"]=t('sb.not_deleted')
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
      flash[:notice] = t('sb.inexisting')
      redirect_to root_url
    end
    unless (current_user.is_admin? || current_user.has_shared_access?(folder))
      flash[:notice] = t('sb.no_permission')
      redirect_to root_url
    end
    unless params[:ids]
      flash[:notice] = t('sb.no_share_selected')
    else
      params[:ids].each do |id|
        if SharedFolder.find_by_id(id).destroy
          flash[:notice] = "#{flash[:notice]} #{t('sb.share_number')} #{id} : #{t('sb.deleted')}<br>"
        else
          flash[:notice] = "#{flash[:notice]} #{t('sb.share_number')} #{id} : #{t('sb.not_deleted')}<br>"
        end
      end
      # some shares were deleted - we have to update folder metadatas
      folder.lists=folder.calc_meta
      unless folder.save
        flash[:notice] = "#{flash[:notice]} #{t('sb.folder_metas')} #{folder.id} #{t('sb.not_updated')}<br>"
      else
        flash[:notice] = "#{flash[:notice]} #{t('sb.folder_metas')} #{folder.id} #{t('sb.updated')}<br>"
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