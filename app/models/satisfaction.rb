##
# the satisfaction model

class Satisfaction < ApplicationRecord

  # february 2019 - to be able to operate in weak logic on the table satisfactions
  #belongs_to :folder
  #validates :folder_id, presence: true
  #belongs_to :user

  belongs_to :poll 

  validates :poll_id, presence: true

end
