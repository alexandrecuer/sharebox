class ClientsController < ApplicationController

  before_action :authenticate_user!

  def index
    if melfrag=params[:melfrag]
      allclients = Client.where("mel LIKE ?", "%#{melfrag}%")
      results=[]
      allclients.each do |c|
        results<< {"email": c.mel,"id": c.id}
      end
    else
      results=Client.all
    end
    render json: results
  end
  
  def show
    results = Client.find_by_id(params[:id])
    render json: results
  end
  
end
