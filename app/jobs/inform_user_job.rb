##
# main class for jobs focusing on mel delivery to public users, on the basis of a shared folder

class InformUserJob < ApplicationJob
  queue_as :default
  
  ##
  # deliver electronic message from current_user to specified email<br>
  # email can be registered in the application or not<br>
  # if not, the message will include the new registration link<br>
  # the message only concerns a specific folder which actually can be considered as a deliverable terminal<br>
  def perform(current_user,email,folder,shared_files,customer,share)
    UserMailer.inform_user(current_user,email,folder,shared_files,customer,share).deliver_now
  end
end
