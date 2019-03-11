##
# the survey model<br>
# very simple at this stage : a survey belongs to a user

class Survey < ApplicationRecord
    belongs_to :user

end
