class Folder < ApplicationRecord

  belongs_to :user

  has_many :assets, :dependent => :destroy
  
  has_many :folders, foreign_key: "parent_id", :dependent => :destroy
  
  has_many :shared_folders, :dependent=> :destroy

  has_many :satisfactions, :dependent=> :destroy
  
  acts_as_tree

  validates :name, presence: true
  
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

end
