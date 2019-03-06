## 
# a very volatile class in order to be able to generate satisfaction surveys out of the folders/assets system

class SurveysController < ApplicationController

    def index
        authenticate_user!
        @surveys = Survey.all.order("id DESC");
        users=current_user.get_all_emails
        results=[]
        @surveys.each_with_index do |s,i|
           results[i]=s.as_json.merge({"owner_mel" => users[s.user_id]})
        end
        render json: results
    end
    
    def getpolls
        allpolls = Poll.all.order("id DESC")
        render json: allpolls
    end
    
    def show
        authenticate_user!
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
    
    def new
        authenticate_user!
        @survey = Survey.new
    end
    
    def create
        authenticate_user!
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
    
    def destroy
        authenticate_user!
        @survey = Survey.find_by_id(params[:id])
        if @survey.user_id == current_user.id || current_user.is_admin?
          @survey.destroy
          render plain: "successfully deleted survey #{params[:id]}"
        else
          render plain: "you do not have sufficient rights"
        end
    end
        
end
