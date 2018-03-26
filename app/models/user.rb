class User < ApplicationRecord

  after_create :complete_suid
  
  has_many :assets, :dependent=> :destroy
  
  has_many :folders, :dependent=> :destroy
  
  has_many :shared_folders, :dependent=> :destroy
  
  has_many :being_shared_folders, :class_name=> "SharedFolder", :foreign_key=> "share_user_id", :dependent=> :destroy
  
  has_many :shared_folders_by_others, :through => :being_shared_folders, :source => :folder
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  
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
                    else mel_text+=u.share_email+" pas encore inscrit<br>"
                end
            end
        end
        #peux t'on faire un perform_later dans un modele ?
        if mel_text != ""
            mel_text="ACTION complete_suid<br>"+mel_text
            ApplicationJob.perform_now(self,mel_text)
        end
    end
    
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
  
  def has_ownership?(folder)
    return true if self.folders.include?(folder)
  end
  
  def has_asset_ownership?(asset)
    return true if self.assets.include?(asset)
  end
  
  def has_shared_folders_from_others?
    return self.shared_folders_by_others.length>0
  end
  
end