class ApplicationJob < ActiveJob::Base
    queue_as :default

    def perform(current_user,text)
    	if text != nil
        	UserMailer.inform_admin(current_user,text).deliver_now
        else
        	UserMailer.inform_user(current_user).deliver_now
        end
    end
    
end