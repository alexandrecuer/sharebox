##
# The user model

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

  ##
  # This method is used after a user creation<br>
  # It realize a concrete action only once in theory<br>
  # It grants, after initial login, admin rights to the first user opening an account<br>
  # you can use db/seeds.rb as an alternative : rake db:seed<br>
  def set_admin
    if User.count == 1
      self.statut = "admin"
      self.save
    end
  end
  
  ##
  # This method is used after a user creation<br>
  # It checks if the shared_folders table has to be completed (column share_user_id)<br>
  # Sends an email to the admin
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
    if mel_text != ""
      mel_text="ACTION complete_suid<br>"+mel_text
      InformAdminJob.perform_now(self,mel_text)
    end
  end

  ##
  # Return true if user has "shared access" on the folder<br>
  # "shared access" means being owner or being granted of a share<br>
  # if folder is a subfolder of a folder shared to the user, we consider the user has shared access on the subfolder
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

  ##
  # Return an hash table (key/value) => (id/email) of all users in a single SQL request
  def get_all_emails
    h = Hash.new
    User.all.each do |u|
      h[u.id] = u.email
    end
    return h
  end
  
  ##
  # Return true if the user owns the folder
  def has_ownership?(folder)
    return true if self.folders.include?(folder)
  end
  
  ##
  # Return true if the user owns the asset
  def has_asset_ownership?(asset)
    return true if self.assets.include?(asset)
  end
  
  ##
  # Return true if user has been awarded some shared folders by private or admin users 
  def has_shared_folders_from_others?
    return self.shared_folders_by_others.length>0
  end

  ##
  # Return true is user is admin
  def is_admin?
    return true if self.statut == "admin"
  end

  ##
  # Return true if user is private
  def is_private?
    return true if self.statut == "private"
  end

  ##
  # Return true if user is public
  def is_public?
    return true if self.statut == "public"
  end

  ##
  # Return true if user has answered to a satisfaction survey on the folder
  def has_completed_satisfaction?(folder)
    return true if Satisfaction.where(folder_id: folder.id, user_id: self.id).length != 0 
  end
  
end
