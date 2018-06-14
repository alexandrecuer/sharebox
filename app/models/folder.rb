class Folder < ApplicationRecord

  belongs_to :user

  has_many :assets, :dependent => :destroy
  
  has_many :folders, foreign_key: "parent_id", :dependent => :destroy
  
  has_many :shared_folders, :dependent=> :destroy

  has_many :satisfactions, :dependent=> :destroy
  
  acts_as_tree

  validates :name, presence: true

  extend ActsAsTree::TreeWalker
  
  def shared?
    !self.shared_folders.empty?
  end

  def is_polled?
    # return true if self.poll_id != nil
    return true if Poll.where(id: self.poll_id).length != 0
  end

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

  # Vrai si le répertoire donné contient des sous-répertoires ou des fichiers
  def has_childrens? 
    if Asset.find_by_folder_id(self.id) || Folder.find_by_parent_id(self.id)
      return true
    else
      return false
    end
  end

  # retourne les fichiers d'un répertoire donné 
  def get_assets
    return Asset.where(folder_id: self.id)
  end


  # Retournes tous les enfants d'un répertoire donné ( sous-répertoires + fichiers )
  def get_childrens
    folders = Folder.where(parent_id: self.id)
    assets = Asset.where(folder_id: self.id)
    childrens = assets + folders

    folders.each do |c|
      if c.has_childrens?
        childrens += c.get_childrens
      end
    end

    return childrens

  end

end
