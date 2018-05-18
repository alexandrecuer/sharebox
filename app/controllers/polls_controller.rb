class PollsController < ApplicationController

 	before_action :authenticate_user!, :check_admin

  	def check_admin
    	if !current_user.is_admin?
      		flash[:notice] = "Vous n'avez pas les droits administrateurs" 
      		redirect_to root_url
    	end
 	end

 	def index 
 	    @poll = Poll.find_by_id(params[:id])
    end

    def edit
        @poll = Poll.find_by_id(params[:id])
        if !@poll
        	flash[:notice] = "Vous ne pouvez pas apporter de modifications à un sondage qui n'existe pas"
    	    redirect_to root_url
        end
    end

    def update
        @poll = Poll.find_by_id(params[:id])
        if @poll.update(poll_params)
            flash[:notice] = "Modifications du sondage sauvegardées"
        end
        redirect_to root_url
    end

 	def new
  	    @poll = current_user.polls.new
 	end

    def show
  	    @poll = Poll.find_by_id(params[:id])
        @hash = current_user.get_all_emails

  	    if !@poll
  	    	flash[:notice] = "Ce numéro de sondage n'existe pas"
  		    redirect_to root_url
  	    end

        respond_to do |format|
            format.html
            format.csv { send_data @poll.to_csv(@hash), filename: "polls-#{Date.today}.csv" }
        end
    end

 	def create 
 		@poll = current_user.polls.new(poll_params)
        # le formulaire est crée seulement si on a un titre, une description et au moins une question ( ouverte ou fermée )
        if ( @poll.closed_names == "" && @poll.open_names == "" )
            flash[:notice] = "Il faut au moins une question dans le formulaire"
        else
 		    @poll.save
 		    flash[:notice] = "Nouveau formulaire crée avec succès"
        end
        redirect_to root_url
 	end

    def destroy
        @poll = Poll.find_by_id(params[:id])
        Folder.where(poll_id: @poll.id).each do |f|
            f.poll_id = nil
            f.save
        end
        @poll.destroy
        flash[:notice] = "Suppression du formulaire réussie"
        redirect_to root_url
    end
  
	private
    def poll_params
	  params.require(:poll).permit(:name, :description, :closed_names, :open_names, :closed_names_number, :open_names_number)
    end

end