##
# the main controller from which all controllers inherit

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :check_lang

  ##
  # this permits to transmit the locale
  # not needed if locale is set within the user's preference
  #def default_url_options
  #  { locale: I18n.locale }
  #end

  ##
  # this fix the locale by reading the lang parameter for the current user
  # called each time a controller is called
  def check_lang
    puts("---------------------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>#{I18n.locale}")
    impl_lang=["fr","en"]
    if current_user
      if impl_lang.include?(current_user.lang)
        I18n.locale=current_user.lang
        puts("******************************#{I18n.locale}")
      end
    end
    if params["locale"]
      puts("a specific locale has been specified in the url")
      I18n.locale=params[:locale]
    end
  end

  def prepare_attached_docs_request
    attachment="uploaded_file"
    req=[]
    req.push("select assets.id, assets.user_id, assets.created_at, assets.folder_id,")
    req.push(" assets.created_at, assets.updated_at,")
    req.push(" users.email as user_name, users.statut as user_statut,")
    req.push(" active_storage_blobs.filename as #{attachment}_file_name,")
    req.push(" active_storage_blobs.content_type as #{attachment}_content_type,")
    req.push(" active_storage_blobs.byte_size as #{attachment}_file_size")
    req.push(" from assets")
    req.push(" INNER JOIN users on assets.user_id = users.id")
    req.push(" INNER JOIN active_storage_attachments ON assets.id = active_storage_attachments.record_id")
    req.push(" INNER JOIN active_storage_blobs ON active_storage_blobs.id = active_storage_attachments.blob_id")
    req.push(" where active_storage_attachments.record_type = ?")
    req
  end

end
