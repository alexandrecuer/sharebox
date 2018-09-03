class UserMailer < ApplicationMailer

  default from: MAIN["admin_mel"]
  
  ##
  # inform admin when a share is created and of all users registration till all pending share emails did not register 
  def inform_admin(current_user,text)
    @user = current_user
    @text = text
    mail(to: MAIN["admin_mel"], subject: 'Activity report') 
  end

  ##
  # generate email in order to inform users if files were shared and/or satisfaction survey was launched<br>
  # this method is used on a specific folder and is called by the folder owner<br>
  def inform_user(current_user,email,folder_id)
    @email = email
    @user = User.find_by_email(email)
    @owner = current_user
    @folder = Folder.find_by_id(folder_id)
    @shared_files = Asset.where("folder_id = "+folder_id)
    
    # email title generation
    # the shared_folders controller forbids all mel from a (shared) folder without files and not linked to a poll
    if @folder.is_polled?
      etitle="Courte enquête de satisfaction"
    end
    if @shared_files.count>0
      ftitle="Livrable(s) en ligne"
    end
    title = "#{ftitle} #{etitle}"
    
    # if email is registered in the database, @user exists
    # we check if @user has already checked his deliverables
    if @user
      @share = SharedFolder.find_by_share_user_id_and_folder_id(@user.id,folder_id)
      # share.message is used to stock the number of 'get' on files - cf assets_controller.rb get method 
      # if share.message is not nil, the share user already checked once his deliverables
      if @share.message
        numberofclics = @share.message.to_i/2
      end   
    end
    
    #generation of the asset(s) list
    t2="Nous avons comptabilisé "
    t3=" accès fichier(s)"
    if @shared_files.count == 1
      asset = @shared_files[0].uploaded_file_file_name
      if numberofclics
        t1="Vous avez déjà visité ce répertoire contenant le fichier suivant :"
        t4="#{t2}#{numberofclics.to_s}#{t3}"
      else
        t1="Un livrable vous a été partagé :"
      end
    elsif @shared_files.count > 1
      asset = "" 
      @shared_files.each.with_index(1) do |f,index|
        asset += index.to_s+") "+f.uploaded_file_file_name+"<br>"
      end
      if numberofclics
        t1="Vous avez déjà visité ce répertoire contenant les fichiers suivants :"
        t4="#{t2}#{numberofclics.to_s}#{t3}"
      else
        t1="#{@shared_files.count} livrables vous ont été partagés :"
      end
    end
    @assetlist = "#{t1}<br>#{asset}<br>#{t4}<br>"
    
    # email delivery
    mail(to: email, from: current_user.email, subject: title)
  end
end
