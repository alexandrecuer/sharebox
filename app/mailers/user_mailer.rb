class UserMailer < ApplicationMailer
    
  def inform_admin(current_user,text)
    @user = current_user
    @text = text
    mail(to: 'cerematest@gmail.com', subject: 'Activity report'.to_s.humanize) do |format|
      format.html
    end
  end

  def inform_user(current_user)
    @user = current_user
    mail(to: @user.email, subject: 'Votre livrable est disponible en ligne'.to_s.humanize) do |format|
      format.html
    end
  end
end
