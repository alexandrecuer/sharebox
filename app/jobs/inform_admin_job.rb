##
# main class for jobs focusing on mel delivery to the site admin

class InformAdminJob < ApplicationJob
  queue_as :default

  ##
  # deliver electronic message to site admin to report on current_user activity<br>
  # the text message should have been prepared somewhere else (in a controller)
  def perform(current_user,text)
  	UserMailer.inform_admin(current_user,text).deliver_now
  end  
end