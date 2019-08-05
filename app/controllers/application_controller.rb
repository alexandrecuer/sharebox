##
# the main controller from which all controllers inherit

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :check_lang
  
  ##
  # this permits to transmit the locale
  # not needed if locale is set within the user's preference
  #def default_url_options
  #  { locale: I18n.locale }
  #end
  
  ##
  # this fix the locale by reading the lang parameter for the current user
  # called each time a controller is called
  def check_lang
    puts("---------------------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>#{I18n.locale}")
    impl_lang=["fr","en"]
    if current_user
      if impl_lang.include?(current_user.lang)
        I18n.locale=current_user.lang
        puts("******************************#{I18n.locale}")
      end
    end
    if params["locale"]
      puts("a specific locale has been specified in the url")
      I18n.locale=params[:locale]
    end
  end
  
end
