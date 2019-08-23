## 
# Manage satisfactions creation within the sharebox site<br>
# A satisfaction is a form intended for the client to express his satisfaction

class SatisfactionsController < ApplicationController
  
  # uses validations module
  
  ##
  # give the ability to an admin to edit a feedback
  def edit
    unless current_user.is_admin?
      flash[:notice] = t('sb.no_permission')
      redirect_to root_url
    else
      unless @satisfaction=Satisfaction.find_by_id(params[:id])
        flash[:notice] = "#{t('sb.inexisting_satisfaction')} #{params[:id]}"
        redirect_to root_url
      else
        @poll = Poll.find_by_id(@satisfaction.poll_id)
      end
    end
  end
  
  ##
  # proceed to the update following an admin order
  def update
    unless current_user.is_admin?
      flash[:notice] = t('sb.no_permission')
      redirect_to root_url
    else
      unless @satisfaction=Satisfaction.find_by_id(params[:id])
        flash[:notice] = "#{t('sb.inexisting_satisfaction')} #{params[:id]}"
        redirect_to root_url
      else
        if @satisfaction.update(satisfaction_params)
          flash[:notice]=t('sb.updated')
        else
          flash[:notice]=t('sb.not_updated')
        end
        @poll = Poll.find_by_id(@satisfaction.poll_id)
        render 'edit'
      end
    end
  end
  
  ##
  # show / update meta datas on satisfactions
  # to upgrade from deprecated versions of colibri (v0 or v1)
  def feedback_metas
    unless current_user.is_admin?
      log="you do not have the permission to update satisfactions metadatas"
    else
      unless params[:update]
        log="checking metadatas on satisfaction records based on the folders'system...\n"
        satisfactions=Satisfaction.where("folder_id > ?",0)
        satisfactions.each do |sat|
          log="#{log} -> satisfaction #{sat.id} on folder (#{sat.folder_id}) metadatas are #{sat.case_number}\n"
        end
      else
        log="updating metadatas on satisfaction records based on the folders'system...\n"
        satisfactions=Satisfaction.where("folder_id > ?",0)
        satisfactions.each do |sat|
          meta=sat.calc_meta
          sat.case_number=meta.join("")
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
  # run a filter on the results of a specific poll
  # route is  /satisfactions/run/:poll_id
  def run
    #authenticate_user!
    polls=[]
    all={}
    poll=Poll.find_by_id(params[:poll_id])
    if poll
      polls.push(poll)
      all["poll_id"]=params[:poll_id]
      all["poll_name"]=poll.name
      unless params[:groups]
        tab=prepare(params,poll.closed_names_number,3)
        satisfactions=Satisfaction.find_by_sql(tab)
      else
        tab=prepare(params,poll.closed_names_number,1)
        satisfactions=Satisfaction.find_by_sql(tab)
        tab=prepare(params,poll.closed_names_number,2)
        satisfactions+=Satisfaction.find_by_sql(tab)
        all["groups"]=params[:groups]
      end
      if params[:start] && params[:end]
        all["from"]=params[:start]
        all["to"]=params[:end]
      end
      if params[:ncap]
        all["ncap"]="#{t('sb.ncap')} #{params[:ncap]}"
      end
      if params[:email]
        all["email"]="#{t('sb.project_manager_feedbacks')} #{params[:email]}"
      end
      # evaluation of sent surveys only if user did not ask for csv export, ncap exploitation or filtering on a specific email
      unless params[:csv] || params[:ncap] || params[:email]
        puts("**************parameters for count_sent_surveys (poll model) [#{all["from"]},#{all["to"]},#{all["groups"]}]")
        nb=poll.count_sent_surveys(all["from"],all["to"],all["groups"])
        all["sent"]=nb
      end
      unless params[:csv]
        if satisfactions.length>0
          stats=poll.stats(satisfactions)
          all["stats"]=stats
        end
        all["satisfactions"]=arrange(polls,satisfactions)
        render json: all
      else
        csv = poll.csv(satisfactions)
        send_data csv, filename: "polls-#{Time.zone.today}.csv"
      end
    else
      render json: {"message": "#{t('sb.inexisting')} - #{t('sb.poll')} #{t('sb.id')} #{params[:poll_id]}"}
    end
  end
  
  ##
  # render a json view of ALL satisfactions answers
  def index
    authenticate_user!
    all={}
    satisfactions= Satisfaction.all.joins(:user).select("satisfactions.*,users.email as email")
    polls= Poll.all
    all["satisfactions"]=arrange(polls,satisfactions)
    render json: all
  end
  
  ##
  # to retrieve for a given registered user all ids for the satisfaction answers collected out of the folders/assets system
  # retieve also, if it exists, the case_number field for a nicer html output
  def freelist
      authenticate_user!
      freesats=current_user.satisfactions.where("folder_id < ?",0).map {|x| {id: x.id, case_number: x.case_number}}
      freesats.each_with_index do |s,i|
         freesats[i][:case_number]=Validations.project_id_reg_exp.match(s[:case_number]).to_s
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
        render plain: "#{t('sb.inexisting')} \n #{t('sb.survey')} #{t('sb.id')} #{params[:id]}"
      else
        if @survey.token != params[:md5]
          render plain: t('sb.incorrect_md5_token')
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
      flash[:notice] = t('sb.inexisting_folder')
      redirect_to root_url
    else
      if current_user.has_ownership?(@current_folder) || current_user.belongs_to_team?
        flash[:notice] = t('sb.team_member_or_folder_owner')
        redirect_to folder_path(@current_folder) and return
      end
      unless current_user.has_shared_access?(@current_folder)
        flash[:notice] = t('sb.unshared_folder')
        redirect_to root_url and return
      end
      unless @current_folder.is_polled?
        flash[:notice] = t('sb.unpolled_folder')
        redirect_to folder_path(@current_folder) and return
      end
      if current_user.has_completed_satisfaction?(@current_folder)
        flash[:notice] = t('sb.already_answered')
        redirect_to folder_path(@current_folder) and return
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
        results["affaire"]=t('sb.inexisting_satisfaction')  
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
              results["affaire"]="#{results["affaire"]}<br>#{t('sb.client')}: #{user.email}"
            end
        else
            results["affaire"]=satisfaction.case_number
        end
        results["date"]=satisfaction.created_at
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
      flash[:notice] = t('sb.inexisting_satisfaction')
      redirect_to root_url
    else
      @current_folder = Folder.find_by_id(@satisfaction.folder_id)
      unless ( current_user.has_shared_access?(@current_folder) || current_user.is_admin? )
        flash[:notice] = t('sb.no_permission')
        redirect_to root_url and return
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
        render plain: "#{t('sb.inexisting')} \n #{t('sb.survey')} #{t('sb.id')} #{@satisfaction.folder_id.abs}"
      else
        poll=Poll.find_by_id(params[:satisfaction][:poll_id])
        if !poll
          render plain: "#{t('sb.inexisting')} \n #{t('sb.poll')} #{t('sb.id')} #{params[:satisfaction][:poll_id]}" 
        else
          if poll.id != survey.poll_id
            render plain: t('sb.mismatch_poll_ids')
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
                render plain: t('sb.new_client_not_saved')
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
        flash[:notice] = t('sb.user_thank_for_feedback')
        @poll = Poll.all.find_by_id(@satisfaction.poll_id)
        @current_folder.lists=@current_folder.calc_meta
        unless @current_folder.save
          flash[:notice] = "#{flash[:notice]} #{t('sb.folder_metas')} #{@current_folder.name} - #{t('sb.id')} #{@current_folder.id}<br>"
          flash[:notice] = "#{flash[:notice]} #{t('sb.not_updated')}"
        end
      else
        flash[:notice] =t('sb.satisfaction_error')
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
      flash[:notice] = t('sb.no_permission')
    else
      if @satisfaction.destroy
        flash[:notice] = t('sb.deleted')
        if folder = Folder.find_by_id(folder_id)
          folder.lists=folder.calc_meta
          unless folder.save
            flash[:notice] = "#{flash[:notice]} #{t('sb.folder_metas_not_recorded')}<br>"
          end
        end
      else
        flash[:notice] = t('sb.not_deleted')
      end
    end
    redirect_to poll_path(@poll)
  end

  private
  
    ##
    # save a free feedback, ie out of the folders/files system
    def save_free_sat(satisfaction, survey)
      if satisfaction.save
        survey.token="disabled#{satisfaction.id}"
        if survey.destroy
          message=t('sb.user_thank_for_feedback')
        else
          #survey.token="disabled#{satisfaction.id}"
          survey.save
          message="#{t('sb.user_thank_for_feedback')} #{t('sb.fmd5_disabled')}"
        end
      else 
        message=t('sb.satisfaction_error')
      end
      message
    end
    
    ##
    # format the title of the feedback<br>
    # used during creation process
    def gentitle(title,client,owner)
      "#{title} - #{Validations.client_pattern}: #{client} - #{Validations.project_manager_pattern}: #{owner}"
    end
    
    ##
    # prepare a SQL request in the satisfactions table<br>
    # implement a jointure on the users and/or folders table<br>
    # params must at least include the poll number<br>
    # possible params are start+end, groups fragment, ncap to track insatisfactions, email
    def prepare(params,closed_names_number,request_type_nbr)

      common="SELECT satisfactions.*,users.email as email, users.groups as groups FROM satisfactions"
      #type 1 gives satisfactions on folder
      type=[]
      type[1]=common
      type[1]="#{type[1]} INNER JOIN folders ON folders.id = satisfactions.folder_id" 
      type[1]="#{type[1]} INNER JOIN users ON users.id = folders.user_id WHERE "
      #type 2 gives satisfactions out of the folders/files system
      type[2]=common 
      type[2]="#{type[2]} INNER JOIN users ON users.id = satisfactions.user_id WHERE satisfactions.folder_id < 0 and "
      #type 3 gives all types of feedbacks but you cannot really filter on groups
      type[3]=common 
      type[3]="#{type[3]} INNER JOIN users ON users.id = satisfactions.user_id WHERE "
      
      request=[]
      tab=[]
      tab[0]=type[request_type_nbr]
      if params[:poll_id]
        request.push("satisfactions.poll_id = ?")
        tab.push(params[:poll_id])
      end
      puts("------SQL preparation function------------we have the following date range [#{params[:start]} ; #{params[:end]}]")
      if Validations.date_reg_exp.match(params[:start]) && Validations.date_reg_exp.match(params[:end])
          time_start = Validations.date_reg_exp.match(params[:start])[0]
          time_end = Validations.date_reg_exp.match(params[:end])[0]
          request.push("(satisfactions.created_at BETWEEN ? AND ?)")
          tab.push("#{time_start}")
          tab.push("#{time_end}")
      end
      if params[:groups]
        unless params[:groups].include?("!")
          request.push("users.groups like ?")
          tab.push("%#{params[:groups]}%")
        else
          request.push("(users.groups is null or users.groups not like ?)")
          tab.push("%#{params[:groups].gsub("!","")}%")
        end
      end
      if params[:ncap]
        ncap=[]
        for i in (1..closed_names_number)
          ncap.push("satisfactions.closed#{i} <= ?")
          tab.push(params[:ncap].to_i)
        end
        ncapstring=ncap.join(" or ")
        request.push("(#{ncapstring})")
      end
      if params[:email]
        request.push("satisfactions.case_number like ?")
        tab.push("%#{Validations.project_manager_pattern}: #{params[:email]}%")
      end
      tab[0]=tab[0]+request.join(" and ")
      tab
    end
    
    ##
    # arrange the satisfaction feedbacks in a human way
    def arrange(polls,satisfactions)
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
        results[i]["date"]=s.created_at
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
      results
    end
  
    def satisfaction_params
      params.require(:satisfaction).permit(:folder_id, :poll_id, :case_number, :closed1, :closed2, :closed3, :closed4, :closed5, :closed6, :closed7, :closed8, :closed9, :closed10, :closed11, :closed12, :closed13, :closed14, :closed15, :closed16, :closed17, :closed18, :closed19, :closed20, :open1, :open2, :open3, :open4, :open5, :open6, :open7, :open8, :open9, :open10, :open11, :open12, :open13, :open14, :open15, :open16, :open17, :open18, :open19, :open20)
    end
end
