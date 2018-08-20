class Folder < ApplicationRecord

  belongs_to :user

  has_many :assets, :dependent => :destroy
  
  has_many :folders, foreign_key: "parent_id", :dependent => :destroy
  
  has_many :shared_folders, :dependent=> :destroy

  has_many :satisfactions, :dependent=> :destroy
  
  acts_as_tree

  validates :name, presence: true

  extend ActsAsTree::TreeWalker
  
  # Retourne Vrai si le dossier a été partagé au moins une fois
  def shared?
    !self.shared_folders.empty?
  end

  # Retourne vrai si un sondage est attribué au dossier 
  def is_polled?
    # return true if self.poll_id != nil
    return true if Poll.where(id: self.poll_id).length != 0
  end

  # Retourne vrai s'il existe au moins une réponse satisfaction pour le dossier
  def has_satisfaction_answer?
    if Satisfaction.find_by_folder_id(self.id)
      return true 
    else 
      return false
    end
  end

  # Vrai si le répertoire donné contient des fichiers
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

  # retourne les fichiers d'un répertoire donné 
  # inutile non - folder.assets donne le même résultat
  def get_assets
    return Asset.where(folder_id: self.id)
  end

  ##
  # Return all subfolders, assets and shares related to the folder, directly or indirectly
  # work recursively
  def get_subs_assets_shares
    folders = Folder.where(parent_id: self.id)
    assets = Asset.where(folder_id: self.id)
    shared_folders = SharedFolder.where(folder_id: self.id)
    childrens = assets + folders + shared_folders

    folders.each do |c|
      if c.has_sub_asset_or_share?
        childrens += c.get_subs_assets_shares
      end
      puts ("end of search for subfolder "+c.name.to_s+ " numéro "+c.id.to_s)
    end
    
    return childrens

  end

end
