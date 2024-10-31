##
# the survey model<br>
# very simple at this stage : a survey belongs to a user

class Survey < ApplicationRecord
    belongs_to :user
    
    validates :description, presence: true
    
    validates :by, presence: true
    
    validates :client_mel, presence: true
    
    ##
    # updates the metas after a survey has been successfully sent to customer
    def update_metas
      metas={}
      if self.metas
        metas=ActiveSupport::JSON.decode(self.metas)
        metas["sent"]+=1
      else
        metas["sent"]=1
      end
      self.metas=ActiveSupport::JSON.encode(metas)
      puts("*************adjusting surveys #{self.id} metas to #{self.metas}***************")
      if self.save
        result=true
      else
        result=false
      end
      result
    end

end
