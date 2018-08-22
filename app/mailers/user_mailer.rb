class UserMailer < ApplicationMailer

  default from: MAIN["admin_mel"]
  
  def inform_admin(current_user,text)
    @user = current_user
    @text = text
    mail(to: MAIN["admin_mel"], subject: 'Activity report')
    
  end

  def inform_user(email)
    @email = email
    @user = User.find_by_email(email)
    mail(to: email, subject: 'Votre livrable est disponible en ligne')
  end
end
