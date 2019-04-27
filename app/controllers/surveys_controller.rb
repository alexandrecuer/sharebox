## 
# a very volatile class in order to be able to generate satisfaction surveys out of the folders/assets system

class SurveysController < ApplicationController
    before_action :inteam

    ##
    # check if user is an affiliated team member from the domain component of its email address
    def inteam
        authenticate_user!
        unless current_user.belongs_to_team?
          redirect_to root_url
        end
    end

    ##
    # if route is /surveys return the whole list of non answered surveys<br>
    # if route is /surveys?csv=1&poll_id=x return a csv file with all the answers for the current_user and the given poll_id
    # if route is /surveys?csv=1&poll_id=x&all=1 return a csv file with all the answers for the given poll_id    
    # results are to be understood out of the folders/assets system    
    def index
        if params[:csv].to_i==1 && params[:poll_id]
          if poll=Poll.find_by_id(params[:poll_id])
            if params[:all].to_i==1
              sqlexp = "satisfactions.folder_id < ?"
              allanswers=poll.satisfactions.joins(:user).select("satisfactions.*,users.email as email").where(sqlexp,0)
            else
              sqlexp = "satisfactions.folder_id < ? and satisfactions.poll_id=?"
              allanswers=current_user.satisfactions.joins(:user).select("satisfactions.*,users.email as email").where(sqlexp,0,params[:poll_id])
            end
            # generate csv file with the csv method of the poll model, using the satisfactions active records
            csv = poll.csv(allanswers)
            send_data csv, filename: "polls-#{Time.zone.today}.csv"
          else 
            render json: {poll: "inexisting poll"}
          end
        else
          surveys = Survey.all.joins(:user).select("surveys.*, users.email as owner_mel").order("id DESC");
          render json: surveys
        end
    end
    
    ##
    # should be in the controller polls - but controller polls is only accessible to admin and should be redesigned<br>
    # if route is /getpolls return all the polls in the colibri<br>
    # if route is /getpolls?mynums=1 return poll numbers containing satisfactions answers out of the folders/assets system for the current_user
    def getpolls
        if params[:mynums].to_i==1
          poll_ids=current_user.satisfactions.where("folder_id < ?",0).pluck("DISTINCT poll_id")
          render json: poll_ids
        else
          allpolls = Poll.all.order("id DESC")
          render json: allpolls
        end
    end
    
    ##
    # show json output of a given survey identified by its id<br>
    # if route is /surveys/:id?email=send, send an email to the client as identified by the survey    
    def show
        survey=Survey.find_by_id(params[:id])
        if survey
          if params[:email]=="send"
            if SurveyClientJob.perform_now(params[:id])
              render plain: "Le lien vers l'enquête a été envoyé par mel à #{survey.client_mel}"
            else
              render plain: "Erreur : le lien vers l'enquête n'a pas pu être envoyé par mel à #{survey.client_mel}"
            end
          else
            render json: survey
          end
        else
          render plain: "cet élément n'existe pas"
        end
    end
    
    ##
    # initiate a new survey - actually open the surveys control panel dor the current user
    def new
        @survey = Survey.new
    end
    
    ##
    # create a new survey
    def create
        @survey = current_user.surveys.new
        @survey.description=params[:description]
        @survey.client_mel=params[:client_mel]
        @survey.by=params[:by]
        @survey.poll_id=params[:poll_id]
        @survey.token = Digest::MD5.hexdigest(@survey.client_mel)
        if @survey.save
          render json: @survey
        else 
          render json: [{"error": "could not save the survey"}]
        end
    end
    
    ##
    # destroy a specific survey
    def destroy
        @survey = Survey.find_by_id(params[:id])
        if @survey.user_id == current_user.id || current_user.is_admin?
          @survey.destroy
          render plain: "Enquête #{params[:id]} supprimée"
        else
          render plain: "Vous n'avez pas les droits nécessaires"
        end
    end
        
end
