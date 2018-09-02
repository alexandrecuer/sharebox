class UserMailer < ApplicationMailer

  default from: MAIN["admin_mel"]
  
  def inform_admin(current_user,text)
    @user = current_user
    @text = text
    mail(to: MAIN["admin_mel"], subject: 'Activity report') 
  end

  def inform_user(current_user,email,folder_id)
    @email = email
    @user = User.find_by_email(email)
    @owner = current_user
    @folder = Folder.find_by_id(folder_id)
    @shared_files = Asset.where("folder_id = "+folder_id)
    
    # default email title
    title = "Livrable(s) disponible(s) en ligne"
    # if email is registered in the database, @user exists
    # we check if @user has already checked his deliverables
    # if so, the message target is to collect the client's satisfaction
    if @user
      @share = SharedFolder.find_by_share_user_id_and_folder_id(@user.id,folder_id)
      # share.message is used to stock the number of 'get' on files - cf assets_controller.rb get method 
      # if share.message is not nil, the share user already checked once his deliverables
      # we can consider we want to retrieve his satisfaction unless the folder is not polled
      # please note a owner can remove at any time the link between the poll and the folder, via the edit méthod of the folder controller
      if @share.message && @folder.is_polled?
        title = "Le Cerema vous sollicite pour une courte enquête satisfaction"
        numberofclics = @share.message.to_i/2
        visited=1
      end   
    end
    #generation of the asset(s) list
    @assetlist=""
    if @shared_files.count == 1
      if visited==1
        @assetlist += "Vous avez déjà visité ce répertoire contenant le fichier suivant :<br>"
      else
        @assetlist += "Un livrable vous a été partagé :<br>"
      end
      @assetlist += @shared_files[0].uploaded_file_file_name+"<br>"
    elsif @shared_files.count > 1
      if visited==1
        @assetlist += "Vous avez déjà visité ce répertoire contenant les fichiers suivants :<br>"
      else
        @assetlist += @shared_files.count.to_s+" livrables vous ont été partagés :<br>"
      end
      @shared_files.each.with_index(1) do |f,index|
        @assetlist += index.to_s+") "+f.uploaded_file_file_name+"<br>"
      end
    end
    if numberofclics
      @assetlist += "Nous avons comptabilisé "+numberofclics.to_s+" accès fichier(s)<br>"
    end
    # At this stage, if there is no file in the folder, we can consider we want to collect a general satisfaction
    # By general satisfaction, we mean satisfaction on the overall business for a client
    # This test on the presence of files in the folder is enough, no need to test also if the folder is polled
    # Indeed, if the folder has got no files and is not polled, the shared_folders controller forbids all email, so we cannot arrive here  
    if !(@shared_files.count > 0)
      title = "Le Cerema vous sollicite pour une courte enquête satisfaction"
    end
    mail(to: email, from: current_user.email, subject: title)
  end
end
