class SharedFolder < ApplicationRecord

	belongs_to :user
	
	belongs_to :folder
    
  validates :share_email, presence: true
  
  validates :folder_id, presence: true
  
  def missing_share_user_id?
    return (self.share_email and not self.share_user_id)
  end
  
  def fetch_user_id_associated_to_email
    return User.where(email: self.share_email).ids[0]
  end
end
