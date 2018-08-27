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
  
  ##
  # Return true is the folder is shared
  def shared?
    !self.shared_folders.empty?
  end

  ##
  # Return true if the folder is polled 
  def is_polled?
    # return true if self.poll_id != nil
    return true if Poll.where(id: self.poll_id).length != 0
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
  def get_assets
    return Asset.where(folder_id: self.id)
  end

  ##
  # Return all subfolders, assets and shares related to the folder, directly or indirectly<br>
  # works recursively
  def get_subs_assets_shares
    folders = Folder.where(parent_id: self.id)
    assets = Asset.where(folder_id: self.id)
    shared_folders = SharedFolder.where(folder_id: self.id)
    childrens = assets + folders + shared_folders

    folders.each do |c|
      if c.has_sub_asset_or_share?
        childrens += c.get_subs_assets_shares
      end
      puts ("end of search for subfolder "+c.name.to_s+ " number "+c.id.to_s)
    end
    
    return childrens

  end

end
