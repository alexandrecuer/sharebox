## 
# Manage satisfactions creation within the sharebox site<br>
# A satisfaction is a form intended for the client to express his satisfaction

class SatisfactionsController < ApplicationController
  
  ##
  # show / update meta datas on satisfactions
  def feedback_metas
    unless current_user.is_admin?
      log="vous n'avez pas les droits suffisants"
    else
      unless params[:update]
        log="checking metadatas on satisfaction records based on the folders'system...\n"
        satisfactions=Satisfaction.where("folder_id > ?",0)
        satisfactions.each do |sat|
          log="#{log} -> satisfaction #{sat.id} on folder (#{sat.folder_id}) metadatas are #{sat.case_number}\n"
        end
      else
        satisfactions=Satisfaction.where("folder_id > ?",0)
        satisfactions.each do |sat|
          meta=sat.calc_meta
          sat.case_number=meta.join("")#gentitle(meta[0],meta[1],meta[2])
          unless sat.save
            log="#{log} -> satisfaction #{sat.id} on folder (#{sat.folder_id}) updating metadatas failed\n"
          else
            log="#{log} -> satisfaction #{sat.id} on folder (#{sat.folder_id}) updating metadatas OK : #{sat.case_number}\n"
          end
        end
      end
    end
    @log=log
  end
  
  ##
  # render a json view of satisfactions answers
  # permits to realize date range request on a given poll_id
  def index
      authenticate_user!
      satisfactions=[]
      polls=[]
      all={}
      if params[:poll_id]
        poll_id=params[:poll_id]
        poll=Poll.find_by_id(poll_id)
        if poll
          polls.push(poll)
          all["poll_id"]=poll_id
          all["poll_name"]=poll.name
          unless params[:start] && params[:end]
            satisfactions= poll.satisfactions.joins(:user).select("satisfactions.*,users.email as email")
          else
            date = /([0-9]{4}-[0-9]{2}-[0-9]{2})/
            if date.match(params[:start]) && date.match(params[:end])
              ts=date.match(params[:start])
              te=date.match(params[:end])
              time_start="#{ts} 00:00:00"
              time_end="#{te} 00:00:00"
              puts("searching feedbacks on poll #{poll_id} from #{time_start} to #{time_end}")
              unless params[:groups]
                expression='satisfactions.created_at BETWEEN ? AND ?'
                satisfactions= poll.satisfactions.joins(:user).select("satisfactions.*,users.email as email").where(expression,time_start,time_end)
              else
                # we first request satisfactions feedbacks collected in the folders/files system
                # we have to check groups value for folders owners > INNER JOIN on folders and then on users
                # not possible to do it with active records as the satisfaction model has been reduced!!
                sql = <<-SQL
                  SELECT satisfactions.*,
                  users.email as email
                  FROM satisfactions 
                  INNER JOIN folders 
                  ON folders.id = satisfactions.folder_id 
                  INNER JOIN users 
                  ON users.id = folders.user_id 
                  WHERE (users.groups LIKE '%#{params[:groups]}%' 
                  and satisfactions.poll_id=#{params[:poll_id]} 
                  and satisfactions.created_at BETWEEN '#{time_start}' AND '#{time_end}');
                SQL
                satisfactions=Satisfaction.find_by_sql(sql)
                # we have now to include the satisfactions collected out the folders/files system
                expression='satisfactions.created_at BETWEEN ? AND ? and satisfactions.folder_id < ? and users.groups LIKE ?'
                satisfactions+=poll.satisfactions.joins(:user).select("satisfactions.*,users.email as email").where(expression,time_start,time_end,0,"%#{params[:groups]}%")
                all["groups"]=params[:groups]
              end
              all["from"]=time_start
              all["to"]=time_end
            end
          end
          unless params[:csv]
            nb=poll.count_sent_surveys(time_start,time_end,params[:groups])
            all["sent"]=nb
            if satisfactions.length>0
              stats=poll.stats(satisfactions)
              all["stats"]=stats
            end
          end
        end
      else
        satisfactions= Satisfaction.all.joins(:user).select("satisfactions.*,users.email as email")
        polls= Poll.all
      end
      # all requests to the database are now done
      # we can process datas - 2 cases - json or csv
      unless params[:csv]
        open={}
        closed={}
        polls.each do |p|
          open["#{p.id}"]=p.hash_open
          closed["#{p.id}"]=p.hash_closed
        end
        results=[]
        satisfactions.each_with_index do |s,i|
          results[i]={}
          results[i]["id"]=s.id
          results[i]["date"]=s.updated_at
          results[i]["affaire"]=s.case_number
          results[i]["folder_id"]=s.folder_id
          results[i]["poll_id"]=s.poll_id
          results[i]["collected_by"]=s.email
          for j in 1..open["#{s.poll_id}"].length
            results[i][open["#{s.poll_id}"]["open#{j}"]]=s["open#{j}"]
          end
          for j in 1..closed["#{s.poll_id}"].length
            results[i][closed["#{s.poll_id}"]["closed#{j}"]]=s["closed#{j}"]
          end
        end
        all["satisfactions"]=results
        render json: all
      else
        if poll
          csv = poll.csv(satisfactions)
          send_data csv, filename: "polls-#{Time.zone.today}.csv"
        else
          render json: {"message": "pas de sondage sous ce numéro"}
        end
      end
  end
  
  ##
  # to retrieve for a given registered user all ids for the satisfaction answers collected out of the folders/assets system
  # retieve also, if it exists, the case_number field for a nicer html output
  def freelist
      authenticate_user!
      freesats=current_user.satisfactions.where("folder_id < ?",0).map {|x| {id: x.id, case_number: x.case_number}}
      freesats.each_with_index do |s,i|
         freesats[i][:case_number]= /[a-zA-Z][0-9]{1,2}[a-zA-Z]{1,2}[0-9]{1,4}/.match(s[:case_number]).to_s
      end
      render json: freesats
  end
  
  ##
  # Show the new form in order to retrieve satisfactions from users not registered in the Colibri<br>
  # WEAK LOGIC PROCESS 2019<br>
  # please note we temporary use the folder_id field to store (-1)*@survey id<br>
  # when satisfaction will be recorded in the database, folder_id field will be recycled to store the client id
  def freenew
      @satisfaction=Satisfaction.new
      @survey=Survey.find_by_id(params[:id])
      if !@survey
        render plain: "Nothing here"
      else
        if @survey.token != params[:md5]
          render plain: "This survey is not for you!"
        else
          @poll=Poll.find_by_id(@survey.poll_id)
          @satisfaction.folder_id=-@survey.id
          @satisfaction.poll_id=@poll.id
          render 'freenew'
        end
      end
  end
  
  ##
  # Show the new form in order for public users to express their satisfaction<br>
  # A public user will access to the form if :<br>
  # - he has a shared access on the folder <br>
  # - the folder is polled<br>
  # - he has not already answered to the form<br>
  # Both types of questions, open and closed, are not required fields
  def new
    authenticate_user!
    @current_folder = Folder.find_by_id(params[:id])
    if !@current_folder
      flash[:notice] = SATISFACTIONS_MSG["inexisting_folder"]
      redirect_to root_url
    else
      if current_user.has_ownership?(@current_folder) || current_user.belongs_to_team?
        flash[:notice] = SATISFACTIONS_MSG["folder_owner"]
        redirect_to folder_path(@current_folder)
      end
      unless current_user.has_shared_access?(@current_folder)
        flash[:notice] = SATISFACTIONS_MSG["unshared_folder"]
        redirect_to root_url
      end
      unless @current_folder.is_polled?
        flash[:notice] = SATISFACTIONS_MSG["unpolled_folder"]
        redirect_to folder_path(@current_folder)
      end
      if current_user.has_completed_satisfaction?(@current_folder)
        flash[:notice] = SATISFACTIONS_MSG["already_answered"]
        redirect_to folder_path(@current_folder)
      end
      @satisfaction = Satisfaction.new
      @satisfaction.folder_id = @current_folder.id 
      @satisfaction.poll_id = @current_folder.poll_id
      @poll = Poll.find_by_id(@current_folder.poll_id)
    end
  end
  
  ##
  # render a json output of a given satisfaction<br>
  # used in the surveys view
  def json
    results={}
    satisfaction = Satisfaction.find_by_id(params[:id])
    unless satisfaction
        results["affaire"]="aucune enquête sous ce numéro"  
    else
        if satisfaction.folder_id > 0
            folder=Folder.find_by_id(satisfaction.folder_id)
            if folder
              results["affaire"]=folder.name
              if folder.case_number.length>0
                results["affaire"]="#{results["affaire"]} (#{folder.case_number})"
              end
            end
            user=User.find_by_id(satisfaction.user_id)
            if user
              results["affaire"]="#{results["affaire"]}<br>Client: #{user.email}"
            end
        else
            results["affaire"]=satisfaction.case_number
        end
        results["date"]=satisfaction.updated_at
        poll=Poll.find_by_id(satisfaction.poll_id)
        open=poll.hash_open
        closed=poll.hash_closed
        for j in 1..open.length
          results[open["open#{j}"]]=satisfaction["open#{j}"]
        end
        for j in 1..closed.length
          if satisfaction["closed#{j}"]
            results[closed["closed#{j}"]]=satisfaction["closed#{j}"]
          else 
            results[closed["closed#{j}"]]=0
          end
        end
    end
    render json: results
  end
  
  ##
  # Show satisfaction answer given a specific id<br>
  # for admins and users with shared access on the folder related to the satisfaction
  def show
    authenticate_user!
    @satisfaction = Satisfaction.find_by_id(params[:id])
    if !@satisfaction
      flash[:notice] = SATISFACTIONS_MSG["inexisting_satisfaction"]
      redirect_to root_url
    else
      @current_folder = Folder.find_by_id(@satisfaction.folder_id)
      unless ( current_user.has_shared_access?(@current_folder) || current_user.is_admin? )
        flash[:notice] = SATISFACTIONS_MSG["access_forbidden"]
        redirect_to root_url
      end
      @poll = Poll.find_by_id(@satisfaction.poll_id)
      render 'new'
    end
  end

  ##
  # Save a satisfaction answer<br>
  # 2 scenarios : <br>
  # 1) folder_id is <0, there is no link with an existing folder - the survey is independent<br>
  #    in that case and at this stage (only), the absolute value of folder_id is temporary equal to survey_id<br>
  # 2) folder_id is >0 and it is a classic satisfaction survey associated to an existing folder<br>
  def create
    if params[:satisfaction][:folder_id].to_i < 0
      @satisfaction = Satisfaction.new(satisfaction_params)
      survey=Survey.find_by_id(@satisfaction.folder_id.abs)
      if !survey
        render plain: "inexisting survey"
      else
        poll=Poll.find_by_id(params[:satisfaction][:poll_id])
        if !poll
          render plain: "inexisting poll"
        else
          if poll.id != survey.poll_id
            render plain: "mismatch : poll ids have been altered"
          else
            client_mel=survey.client_mel
            @satisfaction.case_number= gentitle(survey.description,survey.client_mel,survey.by)
            client=Client.find_by_mel(client_mel)
            if client
              # everything should be fine at this stage - we can fix things
              # folder_id will contain (-1)*client_id
              # user_id will be the user id of the registered user who launched the interaction
              @satisfaction.user_id = survey.user_id
              @satisfaction.folder_id = -client.id
              message=save_free_sat(@satisfaction, survey)
              render plain: message              
            else
              # client is not in the base
              # we save the client without fixing the organisation - it can be done further in the clients controller if needed
              client=Client.new
              client.mel=survey.client_mel
              if client.save
                @satisfaction.user_id = survey.user_id
                @satisfaction.folder_id = -client.id
                message=save_free_sat(@satisfaction, survey)
                render plain: message
              else
                render plain: "could not save new client"
              end
            end
          end
        end
      end
    else
      authenticate_user!
      @satisfaction = Satisfaction.new(satisfaction_params)
      @current_folder = Folder.find_by_id(params[:satisfaction][:folder_id])
      @satisfaction.user_id = current_user.id
      meta=@satisfaction.calc_meta(@current_folder,@current_user)
      @satisfaction.case_number = meta.join("")
      if @satisfaction.save
        flash[:notice] = SATISFACTIONS_MSG["satisfaction_created"]
        @poll = Poll.all.find_by_id(@satisfaction.poll_id)
        @current_folder.lists=@current_folder.calc_meta
        unless @current_folder.save
          flash[:notice] = "#{flash[:notice]} impossible de mettre à jour les metadonnées du répertoire !!<br>"
        end
      else
        flash[:notice] = SATISFACTIONS_MSG["satisfaction_error"]
      end
      render 'new'
    end
  end

  ##
  # Destroy a specific satisfaction<br>
  # The show form of the poll_controller includes a delete button
  def destroy
    authenticate_user!
    @satisfaction = Satisfaction.find_by_id(params[:id])
    folder_id=@satisfaction.folder_id
    @poll = Poll.find_by_id(@satisfaction.poll_id)
    unless current_user.is_admin?
      flash[:notice] = "vous n'avez pas les droits nécessaires"
    else
      if @satisfaction.destroy
        flash[:notice] = "fiche satisfaction supprimée"
        if folder = Folder.find_by_id(folder_id)
          folder.lists=folder.calc_meta
          unless folder.save
            flash[:notice] = "#{flash[:notice]} impossible de mettre à jour les metadonnées du répertoire !!<br>"
          end
        end
      else
        flash[:notice] = "impossible de supprimer la fiche"
      end
    end
    redirect_to poll_path(@poll)
  end

  private
  
    def save_free_sat(satisfaction, survey)
      if satisfaction.save
        survey.token="disabled#{satisfaction.id}"
        if survey.destroy
          message="merci d'avoir pris quelques minutes pour remplir ce sondage"
        else
          survey.token="disabled#{satisfaction.id}"
          survey.save
          message="satisfaction saved but survey not destroyed"
        end
      else 
        message="could not save satisfaction"
      end
      message
    end
    
    def gentitle(title,client,owner)
      "#{title} - Client: #{client} - Chargé d'affaire: #{owner}"
    end
  
    def satisfaction_params
      params.require(:satisfaction).permit(:folder_id, :poll_id, :case_number, :closed1, :closed2, :closed3, :closed4, :closed5, :closed6, :closed7, :closed8, :closed9, :closed10, :closed11, :closed12, :closed13, :closed14, :closed15, :closed16, :closed17, :closed18, :closed19, :closed20, :open1, :open2, :open3, :open4, :open5, :open6, :open7, :open8, :open9, :open10, :open11, :open12, :open13, :open14, :open15, :open16, :open17, :open18, :open19, :open20)
    end
end
