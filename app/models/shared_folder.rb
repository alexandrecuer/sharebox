class SharedFolder < ApplicationRecord

  belongs_to :user

  belongs_to :folder

  validates :share_email, presence: true

  validates :folder_id, presence: true
  
  # Retourne vrai si le partage est donné à un utilisateur qui n'est pas encore inscrit 
  def missing_share_user_id?
    return (self.share_email and not self.share_user_id)
  end
  
  # Retourne l'utilisateur associé à l'adresse email du partage
  def fetch_user_id_associated_to_email
    return User.where(email: self.share_email).ids[0]
  end
end