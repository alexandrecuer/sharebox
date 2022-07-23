##
# The asset model

class Asset < ApplicationRecord

  belongs_to :user

  # active storage configuration
  has_one_attached :uploaded_file
  
  
end
