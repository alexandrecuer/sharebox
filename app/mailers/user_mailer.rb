class UserMailer < ApplicationMailer
    
  def inform_admin(current_user,text)
    @user = current_user
    @text = text
    mail(to: User.find_by_id(1).email, subject: 'Activity report'.to_s.humanize) do |format|
      format.html
    end
  end

  def inform_user(email)
    @email = email
    @user = User.find_by_email(email)

    mail(to: email, subject: 'Votre livrable est disponible en ligne'.to_s.humanize) do |format|
      format.html
    end
  end
end
