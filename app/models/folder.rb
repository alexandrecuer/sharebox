##
# The folder model

class Folder < ApplicationRecord

  belongs_to :user

  has_many :assets, :dependent => :destroy
  
  has_many :folders, foreign_key: "parent_id", :dependent => :destroy
  
  has_many :shared_folders, :dependent=> :destroy

  has_many :satisfactions, :dependent=> :destroy
  
  acts_as_tree

  validates :name, presence: true

  extend ActsAsTree::TreeWalker
  
  attr_accessor :status
  
  ##
  # Return true is the folder is shared
  def shared?
    !self.shared_folders.empty?
  end

  ##
  # Return true if the folder is polled 
  def is_polled?
    #return true if Poll.where(id: self.poll_id).length != 0
    result = self.poll_id
    unless result
      result=false
    end
    puts("folder model - test if folder is polled - result is #{result}")
    return result
  end

  ##
  # Return true if at least a satisfaction answer has been recorded on the folder
  def has_satisfaction_answer?
    if Satisfaction.find_by_folder_id(self.id)
      return true 
    else 
      return false
    end
  end

  ##
  # Return true if the folder has got assets 
  def has_assets? 
    return true if Asset.find_by_folder_id(self.id)
  end

  ##
  # return true if we can find at least one subfolder, asset or share directly related to the folder
  def has_sub_asset_or_share? 
    if Asset.find_by_folder_id(self.id) || Folder.find_by_parent_id(self.id) || SharedFolder.find_by_folder_id(self.id)
      return true
    else
      return false
    end
  end

  # return all assets belonging to a folder (directly - ie its own assets, not the ones in its subfolders)<br>
  # inutile non - folder.assets donne le même résultat
  #def get_assets
  #  return Asset.where(folder_id: self.id)
  #end
  def is_root?
    self.parent_id.nil?
  end

  ##
  # Return all subfolders, assets and shares related to the folder, directly or indirectly<br>
  # works recursively<br>
  # analyzing the 'nearest' children first - operate layer by layer, from the nearest layer to the furthest layer
  def get_subs_assets_shares(i=0)
    puts("**************************working on folder #{self.name} level #{i}")
    folders = Folder.where(parent_id: self.id)
    assets = Asset.where(folder_id: self.id)
    shared_folders = SharedFolder.where(folder_id: self.id)
    childrens = assets + folders + shared_folders
    whitespace=" * "*i
    puts("#{whitespace}BEGIN level #{i}__________________________________________________RECURSIVE SEARCH")
    folders.each do |c|
      if c.has_sub_asset_or_share?
        i+=1
        childrens += c.get_subs_assets_shares(i)
        i-=1
      end
      puts ("end of search for subfolder "+c.name.to_s+ " number "+c.id.to_s)
    end
    puts("#{whitespace}END level #{i}____________________________________________________RECURSIVE SEARCH")
    return childrens
  end
  
  ##
  # returns all subfolders related to the folder, directly or indirectly
  def get_all_sub_folders
    subfolders=self.children
    self.children.each do |children_folder|
      if children_folder.children
        subfolders += children_folder.get_all_sub_folders
      end
    end
    return subfolders
  end
  
  ##
  # Fix user_id to i on all folder's children (assets, subfolders, subassets, shares, subshares)
  def children_give_to(i)
    if self.has_sub_asset_or_share?
      self.get_subs_assets_shares.each do |c|
        c.user_id = i
        c.save
      end
    end
  end
  
  ##
  # is the folder swarmed ?<br>
  # has the folder been created or dropped in a directory belonging to another private user ?
  def is_swarmed?
    self.ancestors.each do |a|
      return true if a.user_id != self.user_id
    end
    return false
  end
  
  ##
  # is the folder swarmed to the specified user ?
  def is_swarmed_to_user?(user)
    return false if user.has_ownership?(self)
    self.ancestors.each do |a|
      return true if a.user_id == user.id
    end
    return false
  end
  
  ##
  # is there a subfolder swarmed by another user ?
  def has_sub_swarmed?
    self.get_all_sub_folders.each do |s|
      return true if s.user_id != self.user_id
    end
    return false
  end
  
  ##
  # is the folder explicitely shared to the user ?<br>
  # by a share in the shared_folders table
  def is_shared_to_user?(user)
    return true if SharedFolder.find_by_share_user_id_and_folder_id(user.id, self.id)
  end

  ##
  # is there a subfolder swarmed by user given in argument ?
  def has_sub_swarmed_to_user?(user)
    return false if user.has_ownership?(self)
    self.get_all_sub_folders.each do |s|
      return true if s.user_id == user.id
    end
    return false  
  end
  
  ##
  # return a list of all metadatas for a given folder id<br>
  # to be inserted in the folder 'lists' field<br>
  # list["shares"] will contain a table with all share ids<br>
  # list["satis"] will contain a table with all satisfaction ids<br>
  # list["swarmed_to"] will contain the id of the user being granted the folder as swarmed<br>
  # to decode when reading the folder record : ActiveSupport::JSON.decode(folder.lists)
  def calc_meta
    meta={}
    # all shares ids associated to the folder
    shares=SharedFolder.where(folder_id: self.id).select("id")
    tab=[]
    shares.each do |s|
      tab << s.id
    end
    meta["shares"]=tab
    # all satisfactions ids associated to the folder
    satisfactions=Satisfaction.where(folder_id: self.id).select("id")
    tab=[]
    satisfactions.each do |s|
      tab << s.id
    end
    meta["satis"]=tab
    #swarming legacy process
    if swid=self.legacy
      meta["swarmed_to"]=swid
    end
    ActiveSupport::JSON.encode(meta)
  end
  
  ##
  # return the id of the user being granted the folder as swarmed<br>
  # for this legacy process, things *MUST* be done in a specific order<br>
  # checking if parent.user_id equals to owner.id before analysing the parent meta 'swarmed_to' would NOT be suitable<br>
  # example : considering a folder1 belonging to user1, shared to user2 and user3<br>
  # user2 creates folder2 inside folder 1 and user3 creates folder3 inside folder2<br>
  # if we check the parent first, the legacy process could conclude that folder3 is swarmed to user2<br>
  # this is not what is expected from the legacy process which has to conclude that folder3 is swarmed to user 1
  def legacy
    owner=User.find_by_id(self.user_id)
    if self.parent_id
      parent=Folder.find_by_id(self.parent_id)
      if swid=parent.get_meta["swarmed_to"]
        puts("{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{ swarmed by legacy #{swid}")
      else
        unless parent.user_id == owner.id
          swid=parent.user_id
        end
      end
    end
    swid
  end
  
  ##
  # return an empty metadata object (for folder creation)
  def initialize_meta
    meta={}
    meta["shares"]=[]
    meta["satis"]=[]
    if swid=self.legacy
      meta["swarmed_to"]=swid
    end
    ActiveSupport::JSON.encode(meta)
  end
  
  ##
  # decoding the meta for an interpretation as a json object
  def get_meta
    meta={}
    meta["shares"]=[]
    meta["satis"]=[]
    if (self.lists)
      meta=ActiveSupport::JSON.decode(self.lists)
    end
    meta
  end
  
  ##
  # execute all 'folder sharing' operations providing a text list of emails (separator ,) <br>
  # update folder metadata if shares are successfully created
  # only folder owner can add new shares<br>
  # if TEAM var exists, could we authorize others users from the team who benefit from a share  ?
  def process_share_emails(emails,current_user)
      result=""
      saved_shares=false
      unless emails && current_user.id == self.user_id
        result="#{I18n.t('sb.stop')}, #{I18n.t('sb.maybe')} :\n - #{I18n.t('sb.no_mel_given')}\n - #{I18n.t('sb.folder_not_for_yu')}"
      else
        email_addresses = emails.split(",")
        email_addresses.each do |email_address|
          email_address=email_address.delete(' ')
          email_to_search=email_address
          if Rails.configuration.sharebox["downcase_email_search_autocomplete"]
            email_to_search=email_to_search.downcase
            share=current_user.shared_folders.where("LOWER(share_email) = ? and folder_id = ?", email_to_search, self.id)[0]
          else
            share=current_user.shared_folders.find_by_share_email_and_folder_id(email_to_search,self.id)
          end
          if email_to_search == current_user.email
            result = "#{result} #{I18n.t('sb.no_share_for_folder_owner')}\n"
          else
            # is the email_address already in the folder's shares ?
            if share
              result = "#{result} #{I18n.t('sb.already_shared_to')} #{email_address}\n"
            else
              shared_folder = current_user.shared_folders.new
              shared_folder.folder_id=self.id
              shared_folder.share_email = email_address
              # We search if the email exist in the user table
              # if not, we'll have to update the share_user_id field after registration
              share_user = User.find_by_email(email_to_search)
              shared_folder.share_user_id = share_user.id if share_user
              if shared_folder.save
                a = "#{I18n.t('sb.shared_to')} #{email_address}"
                result = "#{result} #{a}\n"
                saved_shares = true
              else
                flash[:notice] = "#{result} #{I18n.t('sb.unable_share_for')} #{email_address}\n"
              end
            end
          end
        end
        self.lists=self.calc_meta
        unless self.save
          result = "#{result} #{I18n.t('sb.folder_metas')} : #{I18n.t('sb.not_updated')}\n"
        end
      end
      {"message": result,"saved_shares": saved_shares}
  end
  
  ##
  # inform the customer by email if files/surveys are waiting for him<br>
  # customer can be registered in colibri or not
  def email_customer(current_user,customer_email,share=nil,customer=nil)
    results={}
    shared_files=self.assets
    nb_files=shared_files.length
    puts("**************#{nb_files} file(s) in the folder #{self.id}");
    unless (nb_files>0 || self.is_polled?)
      t1 = I18n.t('sb.cannot_send_mel')
      t2 = I18n.t('sb.empty_folder')
      t3 = I18n.t('sb.unpolled_folder')
      t4 = I18n.t('sb.upload_or_poll_folder')
      results["message"] = "#{t1}\n#{t2}\n#{t3}\n#{t4}"
      results["success"] = false
    else
      if InformUserJob.perform_now(current_user,customer_email,self,shared_files,customer,share)
        results["message"] = "#{I18n.t('sb.mail_sent_to')} #{customer_email}"
        results["success"] = true
      else
        results["message"] = "#{I18n.t('sb.could_not_send_mail_sent_to')} #{customer_email}"
        results["success"] = false
      end
    end
    results
  end
  
  ##
  # move a folder and all related childs (subs,assets,shares,satisfactions) into another one and/or transfer to another user <br>
  # quite costly but it is the ony way....
  def move(destination_folder, destination_user=nil)
    results={}
    childs={}
    unless destination_folder || destination_user
      results["success"]=false
      results["message"]="il faut fournir une donnée : un répertoire de destination, un utilisateur qui héritera du répertoire ou les 2"
    else
      if destination_folder
        case destination_folder
        when 'root'
          self.parent_id=nil
        else
          self.parent_id=destination_folder.id
        end
      end
      if destination_user
        self.user_id=destination_user.id
      end
      self.lists=self.calc_meta
      if self.save
        results["success"]=true
        results["message"]="sauvegarde du répertoire: OK\n"
        childs=self.get_subs_assets_shares
        childs.each do |c|
          if destination_user
            c.user_id = destination_user.id
          end
          #we check if the child is a folder
          if /lists/.match(c.attributes.keys.to_s)
            results["message"]="#{results["message"]} NOTA : l'enfant #{c.id} est un répertoire\n"
            c.lists=c.calc_meta
          end
          unless c.save
            results["success"]=false
            results["message"]="#{results["message"]} impossible de sauvegarder l'enfant #{c.id}\n"
          else
            results["message"]="#{results["message"]} sauvegarde de l'enfant #{c.id}: OK\n"
          end
        end
      else
        results["success"]=false
        results["message"]="impossible de sauvegarder le répertoire"
      end
    end
    results.merge!("folder": self.as_json)
    results.merge!("childs": childs.as_json)
    results
  end
  
end
