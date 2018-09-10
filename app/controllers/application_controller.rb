##
# the main controller from which all controllers inherit

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end
