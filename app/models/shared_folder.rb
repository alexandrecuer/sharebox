class SharedFolder < ApplicationRecord

  belongs_to :user

  belongs_to :folder

  validates :share_email, presence: true

  validates :folder_id, presence: true
  
  ##
  # Return true if share refers to an email that has not yet created an account
  def missing_share_user_id?
    return (self.share_email and not self.share_user_id)
  end
  
  ##
  # Return user id associated to share_email
  # used only when share_user_id is missing
  # it happens when a share is given to an email that has not created an account in the database
  # the system uses the method fetch_user_id_associated_to_email after the user's registration
  # and fill the share_user_id field in the table shared_folders
  def fetch_user_id_associated_to_email
    return User.where(email: self.share_email).ids[0]
  end
end