class InformUserJob < ApplicationJob
  queue_as :default

  def perform(email)
    UserMailer.inform_user(email).deliver_now
  end
end
