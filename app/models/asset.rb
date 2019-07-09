##
# The asset model

class Asset < ApplicationRecord

  belongs_to :user

  # this is the new active storage configuration
  if Rails.application.config.paperclip==0
    #if Rails.application.config.local_storage==1
      has_one_attached :uploaded_file
    #end
  end

  # this was the old paperclip configuration
  # s3_permissions permet d'uploader des fichiers sur S3 en mode private....
  # par defaut paperclip procède à des uploads en mode public  
  if Rails.application.config.paperclip==1
    if Rails.application.config.local_storage==1
      has_attached_file :uploaded_file,
                      url: '/forge/get/:id/:filename',
                      path: ':rails_root/forge/attachments/:id/:filename'
    elsif Rails.application.config.local_storage==0
      has_attached_file :uploaded_file,
                      url: ENV.fetch('AWS_URL'),
                      path: '/forge/attachments/:id/:filename',
                      s3_permissions: :private

    end
    validates :uploaded_file, presence: true

    validates_attachment_size :uploaded_file, :less_than => 50.megabytes

    #validates_attachment :uploaded_file, content_type: { content_type: ["image/jpeg"] }
    #validates_attachment_content_type :data, content_type: /\Aimage/
    validates_attachment :uploaded_file, content_type: { content_type: ["application/vnd.oasis.opendocument.text", "application/pdf", "image/jpeg",  "image/gif", "image/png", "application/zip"]}

    #do_not_validate_attachment_file_type :uploaded_file
  end
  
  
end
