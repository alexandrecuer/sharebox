class InformUserJob < ApplicationJob
  queue_as :default

  def perform(current_user,email,folder_id)
    UserMailer.inform_user(current_user,email,folder_id).deliver_now
  end
end
