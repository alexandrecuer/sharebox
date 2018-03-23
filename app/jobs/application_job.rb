class ApplicationJob < ActiveJob::Base
    queue_as :default

    def perform(current_user,text)
        UserMailer.inform_admin(current_user,text).deliver_now
    end
    
end