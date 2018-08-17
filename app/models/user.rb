class User < ApplicationRecord

  after_create :complete_suid, :set_admin
  
  has_many :assets, :dependent=> :destroy
  
  has_many :folders, :dependent=> :destroy
  
  has_many :shared_folders, :dependent=> :destroy
  
  has_many :being_shared_folders, :class_name=> "SharedFolder", :foreign_key=> "share_user_id", :dependent=> :destroy
  
  has_many :shared_folders_by_others, :through => :being_shared_folders, :source => :folder

  has_many :polls, :dependent=> :destroy

  has_many :satisfactions, :dependent=> :destroy
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Permet au premier utilisateur qui s'inscrit sur l'application d'avoir automatiquement le statut d'administrateur
  def set_admin
    if User.count == 1
      self.statut = "admin"
      self.save
    end
  end
  
  # Méthode appelée lors de l'inscription d'un utilisateur, elle envoit un mail à l'administrateur
  def complete_suid
    @shared_folders=SharedFolder.where("share_user_id IS NULL")
    mel_text=""
    @shared_folders.each do |u|
      if u.missing_share_user_id?
        if u.fetch_user_id_associated_to_email
          u.share_user_id=u.fetch_user_id_associated_to_email
          if u.save
            mel_text+="share_user_id("+u.share_user_id.to_s+") -> partage("+u.id.to_s+")<br>"
          end
        else
          mel_text+=u.share_email+" pas encore inscrit<br>"
        end
      end
    end
    #peux t'on faire un perform_later dans un modele ?
    if mel_text != ""
      mel_text="ACTION complete_suid<br>"+mel_text
      InformAdminJob.perform_now(self,mel_text)
    end
  end

  # Retourne vrai si l'utilisateur a accès au dossier passé en paramètre
  def has_shared_access?(folder)
    return true if self.folders.include?(folder)
    return true if self.shared_folders_by_others.include?(folder)
    return_value = false
    folder.ancestors.each do |ancestor_folder|
      return_value = self.shared_folders_by_others.include?(ancestor_folder)
      if return_value 
        return true
      end
    end
    return false
  end

  # Permet de récupérer un couple clé / valeur => id / email de chaque utilisateur en une seule requête SQL
  def get_all_emails
    h = Hash.new
    User.all.each do |u|
      h[u.id] = u.email
    end
    return h
  end
  
  # Retourne vrai si l'utilisateur détient le dossier passé en paramètre
  def has_ownership?(folder)
    return true if self.folders.include?(folder)
  end
  
  # Retourne vrai si l'utilisateur détient le fichier passé en paramètre
  def has_asset_ownership?(asset)
    return true if self.assets.include?(asset)
  end
  
  # Retourne vrai si l'utilisateur a reçu des partages de dossiers
  def has_shared_folders_from_others?
    return self.shared_folders_by_others.length>0
  end

  # Retourne vrai si l'utilisateur est administrateur
  def is_admin?
    return true if self.statut == "admin"
  end

  # Retourne vrai si l'utilisateur a un statut privé
  def is_private?
    return true if self.statut == "private"
  end

  # Retourne vrai si l'utilisateur a un statut public
  def is_public?
    return true if self.statut == "public"
  end

  # Retourne vrai si l'utilisateur a répondu à une enquête satisfaction sur le dossier passé en paramètre
  def has_completed_satisfaction?(folder)
    return true if Satisfaction.where(folder_id: folder.id, user_id: self.id).length != 0 
  end
  
end
