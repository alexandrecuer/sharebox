##
# manage a clients'list

class ClientsController < ApplicationController

  before_action :authenticate_user!

  ##
  # return a json list of all clients<br>
  # if route is clients?melfrag=some_text, return a json list of clients with emails containing some_text 
  def index
    if melfrag=params[:melfrag]
      if Rails.configuration.sharebox["downcase_email_search_autocomplete"]
        melfrag=melfrag.downcase
        allclients = Client.where("LOWER(mel) LIKE ?", "%#{melfrag}%")
      else
        allclients = Client.where("mel LIKE ?", "%#{melfrag}%")
      end
      results=[]
      allclients.each do |c|
        results<< {"email": c.mel,"id": c.id}
      end
    else
      results=Client.all
    end
    render json: results
  end
  
  ##
  # show a client given its id number
  def show
    results = Client.find_by_id(params[:id])
    render json: results
  end
  
end
