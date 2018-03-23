class Folder < ApplicationRecord

  belongs_to :user

  has_many :assets, :dependent => :destroy
  
  has_many :folders, foreign_key: "parent_id", :dependent => :destroy
  
  has_many :shared_folders, :dependent=> :destroy
  
  acts_as_tree

  validates :name, presence: true
  
  def shared?
    !self.shared_folders.empty?
  end

end
