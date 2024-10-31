##
# mailing system for the admin (automatic, to follow shares and new users registration)<br>
# mailing system for the private users (manual) 

class UserMailer < ApplicationMailer

  default from: Rails.configuration.sharebox["admin_mel"]
  
  ##
  # inform admin when a share is created and of all users registration till all pending share emails did not register 
  def inform_admin(current_user,text)
    @user = current_user
    @text = text
    mail(to: Rails.configuration.sharebox["admin_mel"], subject: 'Activity report') 
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
      etitle=t('mel.satisfaction_survey')
    end
    if @shared_files.length>0
      ftitle=t('mel.online_deliverable')
    end
    title = "#{ftitle} #{etitle}"
    
    
    # share.message is used to stock the number of 'get' on files - cf assets_controller.rb get method 
    # if share.message is not nil, the custumer already checked once his deliverables
    if @share.message
      numberofclics = @share.message.to_i/2
    end
    
    #_______________________________
    #generation of the asset(s) list
    t2="#{t('mel.we_count')} "
    t3=" #{t('mel.file_clics')}"
    if @shared_files.length == 1
      asset = @shared_files[0].uploaded_file_file_name
      if numberofclics
        t1="#{t('mel.one_file_folder_visited')} :"
        t4="#{t2}#{numberofclics}#{t3}"
      else
        t1="#{t('mel.one_file_shared')} :"
      end
    elsif @shared_files.length > 1
      asset = "" 
      #@shared_files.each.with_index(1) do |f,index|
      @shared_files.each_with_index do |f,index|
        asset += "#{index}) #{f.uploaded_file_file_name}<br>"
      end
      if numberofclics
        t1="#{t('mel.many_files_folder_visited')} :"
        t4="#{t2}#{numberofclics}#{t3}"
      else
        t1="#{@shared_files.length} #{t('mel.many_files_shared')} :"
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
    title="[#{Rails.configuration.sharebox["company"]}][#{t('mel.satisfaction_survey')}]#{@survey.description}"
    mail(to: @survey.client_mel, from: @survey.by, subject: title)
  end
  
end
