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
  
  has_many :surveys, :dependent=> :destroy

  has_many :satisfactions, :dependent=> :destroy
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  
  ##
  # check if user belongs to the team if any
  def belongs_to_team?
    a = true
    if ENV['TEAM']
      a = self.email.split("@")[1]==ENV.fetch('TEAM')
    end
    a
  end
  
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
    missing_share_user_id_filled=""
    unregistered_emails=""
    @shared_folders.each do |u|
      folder=Folder.find_by_id(u.folder_id)
      share="share (#{u.id}) on folder #{folder.name} (#{u.folder_id})"
      if u.missing_share_user_id?
        if u.fetch_user_id_associated_to_email
          u.share_user_id=u.fetch_user_id_associated_to_email
          if u.save
            missing_share_user_id_filled="#{missing_share_user_id_filled} -> filled share_user_id (#{u.share_user_id}) for #{share}<br><br>"
          end
        else
          unregistered_emails="#{unregistered_emails} -> #{u.share_email} not yet registered for #{share}<br><br>"
        end
      end
    end
    mel_to_admin="#{missing_share_user_id_filled}#{unregistered_emails}"
    if mel_to_admin != ""
      mel_to_admin="<h2>Report - complete_suid user method</h2><br><br>#{mel_to_admin}"
      InformAdminJob.perform_now(self,mel_to_admin)
    end
  end

  ##
  # Return true if user has "shared access" on the folder<br>
  # "shared access" means being owner or being granted of a share<br>
  # if folder is a subfolder of a folder shared to the user, we consider the user has shared access on the subfolder
  # QUITE SQL COSTLY - do not use heavily - DO NOT USE IN LOOPS !!!!!!!!!!!!!
  def has_shared_access?(folder)
    puts("shared_access_testing...")
    
    return true if self.is_admin?
    
    # is the folder owned by the user ?
    folders=self.folders
    return true if folders.include?(folder)
    oids=[]
    folders.each do |o|
      oids.push(o.id)
    end
    puts("all folder ids owned by the user: #{oids}")
    
    # has the folder been shared to the user ?
    sharedfolders=self.shared_folders_by_others
    return true if sharedfolders.include?(folder)
    sids=[]
    sharedfolders.each do |s|
      sids.push(s.id)
    end
    puts("all folder ids shared to the user: #{sids}")
    
    # if the user owns or was shared one of the folder's ancestors, he has shared access on the folder
    puts("&&&&&&&&&&&&&&&&getting all ancestors active records")
    ancestors=folder.ancestors
    puts("BEGIN ---------------- ancestors exploration")
    ancestors.each do |ancestor_folder|
      #these two instructions are too costly
      #return true if sharedfolders.include?(ancestor_folder)
      #return true if folders.include?(ancestor_folder)
      return true if sids.include?(ancestor_folder.id)
      return true if oids.include?(ancestor_folder.id)
    end
    puts("END ---------------- ancestors exploration")
    
    # CAUTION - normally the following happens rarely, mostly with the old PRIMITIVE style of browsing, ie breadcrumb navigation
    # it is not really used by the new API-based Ajax browsing style, except with the go_up button !!
    # if you have swarmed a folder, you need to access to the whole tree of the primo ancestor of the folder 
    # by primo ancestor, we mean the root folder which hosts directly or indirectly the folder 
    # we explore all the subfolders directly or indirectly related to the primo ancestor of the folder
    # if one folder belongs to the user, the user is considered to have a shared access
    # HEAVY COST HEAVY COST OMG
    puts("BEGIN ---------------- base searching")
    if folder.is_root?
      base = folder
    else 
      base = ancestors.reverse[0]
    end
    puts("END ---------------- base searching")
    puts("BEGIN ---------------- tree exploration from main root folder")
    base.get_all_sub_folders.each do |sub|
      return true if self.folders.include?(sub)
    end
    
    return false
    
  end
  
  ##
  # super user access on a folder is true if folder is owned or swarmed to the user<br>
  # a low cost method using the metadatas
  def has_su_access?(folder)
    puts("superuser_access_testing...")
    return true if self.folders.include?(folder)
    return true if folder.get_meta["swarmed_to"]==self.id
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
    # not sure but include? does not burn a SQL request
    #return true if self.folders.include?(folder)
    puts("{{{{{{{{{{folder stamped to belong to user #{folder.user_id} and current user is number #{self.id}")
    return true if folder.user_id==self.id
  end
  
  ##
  # Return true if the user owns the asset
  def has_asset_ownership?(asset)
    #return true if self.assets.include?(asset)
    return true if asset.user_id==self.id
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
  # return the corresponding satisfaction record if user has answered to a satisfaction survey on the folder
  # return false if user has not answered
  # if a satisfaction list record is given, do not burn a SQL request
  def has_completed_satisfaction?(folder, satisfactions=nil)
    unless satisfactions
      #return true if Satisfaction.where(folder_id: folder.id, user_id: self.id).length != 0
      result=self.satisfactions.find_by_folder_id(folder.id)
      unless result
        result=false
      end
    else
      result=false
      satisfactions.each do |s|
        if s.folder_id==folder.id && s.user_id==self.id 
          result = s
        end
      end
      
    end
    puts("user model - test if current_user has completed satisfaction - result is #{result}")
    return result
  end
  
  ##
  # Return all users with email containing the specific term
  def self.search(term)
    where('LOWER(email) LIKE :term', term: "%#{term.downcase}%")
  end
  
end
