##
# main home page

class HomeController < ApplicationController

  before_action :authenticate_user!
    
end