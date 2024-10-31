##
# main class for jobs focusing on mel delivery to public users, on the basis of a shared folder

class SurveyClientJob < ApplicationJob
  queue_as :default
  
  ##
  # deliver electronic message from a specific survey<br>
  def perform(survey_id)
    UserMailer.send_free_survey(survey_id).deliver_now
  end
end
