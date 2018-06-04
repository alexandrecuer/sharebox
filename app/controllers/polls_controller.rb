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
        array = poll_params[:closed_names].split(";") + poll_params[:open_names].split(";")
        if array.uniq.count != array.size
            flash[:notice] = "Un sondage ne peut contenir des questions identiques"
        else
            if @poll.update(poll_params)
                flash[:notice] = "Modifications du sondage sauvegardées"
            end
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
        if (( @poll.open_names == "" && @poll.closed_names == "" ) || @poll.description == "" || @poll.name == "" )
            flash[:notice] = "Il manque des champs obligatoires dans le formulaire"
        else
            array = @poll.get_names
            if array.uniq.count != array.size
                flash[:notice] = "Il n'est pas possible de créer un formulaire avec des questions identiques"
            else
 		        @poll.save
 		        flash[:notice] = "Nouveau formulaire crée avec succès"
            end
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