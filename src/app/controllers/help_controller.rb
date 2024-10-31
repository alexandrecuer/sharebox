class HelpController < ApplicationController
  #before_action :authenticate_user!

  def index
    unless current_user.is_admin?
      redirect_to root_url
    end
  end
  
  def i18n
    lang=I18n.locale
    filepath="#{Rails.root}/config/locales/sb.#{lang}.yml"
    if params[:cat] && params[:field]
      result = YAML.load_file(filepath)["#{lang}"]["sb"][params[:cat]][params[:field]]
      if result 
        conf = { "result": result}
      else
        conf = { "result": "undefined"}
      end
    else
      if params[:cat]
        conf = YAML.load_file(filepath)["#{lang}"]["sb"][params[:cat]]
      elsif params[:field]
        result = YAML.load_file(filepath)["#{lang}"]["sb"][params[:field]]
        if result 
          conf = { "result": result}
        else
          conf = { "result": "undefined"}
        end
      else
        conf = YAML.load_file(filepath)["#{lang}"]["sb"]
      end
    end
    render json: conf
  end
  
end
