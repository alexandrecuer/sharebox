class Asset < ApplicationRecord

  belongs_to :user
  
  # mettre s3_permissions permet d'uploader des fichiers sur S3 en mode private....
  # par defaut paperclip procède à des uploads en mode public
  has_attached_file :uploaded_file,
                    #url: '/forge/get/:id/:filename',             
                    #path: ':rails_root/forge/attachments/:id/:filename'
                    url: ENV.fetch('AWS_URL'),
                    path: '/forge/attachments/:id/:filename',
                    s3_permissions: :private
					
  validates :uploaded_file, presence: true
  
  validates_attachment_size :uploaded_file, :less_than => 50.megabytes

  #validates_attachment :uploaded_file, content_type: { content_type: ["image/jpeg"] }
  #validates_attachment_content_type :data, content_type: /\Aimage/
  validates_attachment :uploaded_file, content_type: { content_type: ["application/vnd.oasis.opendocument.text", "application/pdf", "image/jpeg",  "image/gif", "image/png", "application/zip"]}
  
  #do_not_validate_attachment_file_type :uploaded_file
  
end
