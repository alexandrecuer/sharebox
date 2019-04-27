##
# the satisfaction model

class Satisfaction < ApplicationRecord

  # february 2019
  # to be able to operate in weak logic on the table satisfactions
  # the following 2 lines are commented....
  #belongs_to :folder
  #validates :folder_id, presence: true
  belongs_to :user

  belongs_to :poll 

  validates :poll_id, presence: true
  
  ##
  # return the meta table for the satisfaction feedback
  def calc_meta(folder=nil,client=nil)
    unless folder
      folder=Folder.find_by_id(self.folder_id)
    end
    unless folder.case_number == ""
      title="#{folder.name} (#{folder.case_number})"
    else
      title=folder.name
    end
    owner=User.find_by_id(folder.user_id)
    unless client
      client=User.find_by_id(self.user_id)
    end
    result=[]
    result.push(title)
    result.push(" - Client: ")
    result.push(client.email)
    result.push(" - Chargé d'affaire: ")
    result.push(owner.email)
    result
  end
  
  

end
