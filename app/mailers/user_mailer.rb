##
# mailing system for the admin (automatic, to follow shares and new users registration)<br>
# mailing system for the private users (manual) 

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
  # generate email in order to inform users that files were shared and/or satisfaction survey was launched<br>
  # this method is used on a specific folder and is called by the folder owner<br>
  def inform_user(current_user,customer_email,folder,shared_files=nil,customer=nil,share=nil)
    @customer_email = customer_email
    @owner = current_user
    @folder = folder
    unless customer
      @customer = User.find_by_email(customer_email)
    else
      @customer = customer
    end
    # files & deliverables
    unless shared_files
      @shared_files = @folder.assets
    else
      @shared_files = shared_files
    end
    # related share
    unless share
      if @customer
        @share = SharedFolder.find_by_share_user_id_and_folder_id(@customer.id,folder.id)
      end
    else
      @share = share
    end
    
    # email title generation
    # the shared_folders controller forbids all mel from a (shared) folder without files and not linked to a poll
    if @folder.is_polled?
      etitle="Courte enquête de satisfaction"
    end
    if @shared_files.length>0
      ftitle="Livrable(s) en ligne"
    end
    title = "#{ftitle} #{etitle}"
    
    
    # share.message is used to stock the number of 'get' on files - cf assets_controller.rb get method 
    # if share.message is not nil, the custumer already checked once his deliverables
    if @share.message
      numberofclics = @share.message.to_i/2
    end
    
    #_______________________________
    #generation of the asset(s) list
    t2="Nous avons comptabilisé "
    t3=" accès fichier(s)"
    if @shared_files.length == 1
      asset = @shared_files[0].uploaded_file_file_name
      if numberofclics
        t1="Vous avez déjà visité ce répertoire contenant le fichier suivant :"
        t4="#{t2}#{numberofclics}#{t3}"
      else
        t1="Un livrable vous a été partagé :"
      end
    elsif @shared_files.length > 1
      asset = "" 
      #@shared_files.each.with_index(1) do |f,index|
      @shared_files.each_with_index do |f,index|
        asset += "#{index}) #{f.uploaded_file_file_name}<br>"
      end
      if numberofclics
        t1="Vous avez déjà visité ce répertoire contenant les fichiers :"
        t4="#{t2}#{numberofclics}#{t3}"
      else
        t1="#{@shared_files.length} livrables vous ont été partagés :"
      end
    end
    @assetlist = "#{t1}<br>#{asset}<br>#{t4}<br>"
    
    # email delivery
    mail(to: customer_email, from: current_user.email, subject: title)
  end

  ##
  # generate email in order to alert a non registered client of a survey
  def send_free_survey(id)
    @survey = Survey.find_by_id(id)
    title="[Cerema][courte enquête de satisfaction]#{@survey.description}"
    mail(to: @survey.client_mel, from: @survey.by, subject: title)
  end
  
  def send_feedback
    
  end
end
