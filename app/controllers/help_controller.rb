class HelpController < ApplicationController
  before_action :authenticate_user!

  def index
    unless current_user.is_admin?
      redirect_to root_url
    end
  end
end
