##
# main mailer class

class ApplicationMailer < ActionMailer::Base
  
  default from: ENV.fetch('GMAIL_USERNAME')

end
