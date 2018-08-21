class UserMailer < ApplicationMailer
    
  def inform_admin(current_user,text)
    @user = current_user
    @text = text
    mail(to: MAIN["admin_mel"], subject: 'Activity report')
    
  end

  def inform_user(email)
    @email = email
    @user = User.find_by_email(email)
    #attachments.inline["logo.jpg"] = File.read("#{Rails.root}/app/assets/images/logo.jpg")
    mail(to: email, subject: 'Votre livrable est disponible en ligne')
  end
end
