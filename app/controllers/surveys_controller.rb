## 
# a very volatile class in order to be able to generate satisfaction surveys out of the folders/assets system

class SurveysController < ApplicationController
    before_action :inteam

    ##
    # check if user is admin or is an affiliated team member from the domain component of its email address
    def inteam
        authenticate_user!
        unless current_user.belongs_to_team? || current_user.is_admin?
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
          tab=[]
          tab[0]=""
          if params[:groups]
            tab[0]="#{tab[0]}users.groups like ?"
            tab.push("%#{params[:groups]}%")
          end
          if params[:time_start] && params[:time_end]
            tab[0]="#{tab[0]} and surveys.created_at BETWEEN ? AND ?"
            tab.push(params[:time_start])
            tab.push(params[:time_end])
          end
          # check if the sql 'where' instruction begin by " and " and if yes truncate it
          if /^\sand\s/.match(tab[0])
            tab[0].gsub!(/^\sand\s/,"")
          end
          if tab[0].length>0
            surveys = Survey.all.joins(:user).select("surveys.*, users.email as owner_mel").where(tab).order("id DESC")
          else
            surveys = Survey.all.joins(:user).select("surveys.*, users.email as owner_mel").order("id DESC")
          end
          render json: surveys
        end
    end
    
    ##
    # 
    def fill_empty_metas
      if params[:poll_id]
        poll=Poll.find_by_id(params[:poll_id])
        unless poll
          @log="aucun sondage sous ce numéro"
        else
          @log=poll.consider_all_pending_surveys_sent_once
        end
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
              message="Le lien vers l'enquête a été envoyé par mel à #{survey.client_mel}"
              if survey.update_metas
                render plain: message
              else
                render plain: "#{message}\n Mais le compteur de relance n'a pas été mis à jour"
              end
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
