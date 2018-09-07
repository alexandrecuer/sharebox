##
# User managing within the sharebox site

class HomeController < ApplicationController

  before_action :authenticate_user!
    
  
end