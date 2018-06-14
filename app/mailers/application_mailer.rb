class ApplicationMailer < ActionMailer::Base
  
  default from: ENV.fetch('GMAIL_USERNAME')
  #default from: %("#{'L\'ADMIN DU CLOUD DES RAPPORTS - Cerema'}" <#{'cuer.ac@gmail.com'}>)
end
