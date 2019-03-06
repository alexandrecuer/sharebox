## 
# Manage satisfactions creation within the sharebox site<br>
# A satisfaction is a form intended for the client to express his satisfaction

class SatisfactionsController < ApplicationController
  
  ##
  # render a json view of all satisfactions answers
  def index
      satisfactions= Satisfaction.all
      polls= Poll.all
      open=[]
      closed=[]
      polls.each do |p|
        opens=p.open_names.split(";")
        closes=p.closed_names.split(";");
        open[p.id]={}
        closed[p.id]={}
        opens.each_with_index do |o,i|
          open[p.id]["open#{i+1}"]=o.strip
        end
        closes.each_with_index do |c,i|
          closed[p.id]["closed#{i+1}"]=c.strip
        end  
      end
      results=[]
      satisfactions.each_with_index do |s,i|
        results[i]={}
        results[i]["id"]=s.id
        results[i]["date"]=s.updated_at
        results[i]["affaire"]=s.case_number
        results[i]["folder_id"]=s.folder_id
        if s.folder_id > 0
          results[i]["folder_name"]=Folder.find_by_id(s.folder_id).name
        else
          results[i]["folder_name"]=""
        end
        if s.user_id > 0
          results[i]["de"]=User.find_by_id(s.user_id).email        
          results[i]["pour"]=User.find_by_id(Folder.find_by_id(s.folder_id).user_id).email
        else
          melregexp = /[^\W][a-zA-Z0-9_\-]+(\.[a-zA-Z0-9_\-]+)*\@[a-zA-Z0-9_\-]+(\.[a-zA-Z0-9_\-]+)*\.[a-zA-Z]{2,4}/
          client_mel = melregexp.match(s.case_number);
          if client_mel
            temp=s.case_number.sub(client_mel[0], "")
            by_mel = melregexp.match(temp)
            if by_mel
              results[i]["de"]=by_mel[0]
              results[i]["pour"]=client_mel[0]
            end
          end
        end
        results[i]["poll_id"]=s.poll_id
        for j in 1..open[s.poll_id].length
          results[i][open[s.poll_id]["open#{j}"]]=s["open#{j}"]
        end
        for j in 1..closed[s.poll_id].length
          results[i][closed[s.poll_id]["closed#{j}"]]=s["closed#{j}"]
        end
      end
      render json: results
  end
  
  ##
  # to retrieve for a given registered user all ids for the satisfaction answers collected out of the folders/assets system
  def freelist
      authenticate_user!
      id = -current_user.id
      @surveys=Satisfaction.where(user_id: id).map {|x| {id: x.id}}
      render json: @surveys
  end
  
  ##
  # Show the new form in order to retrieve satisfactions from users not registered in the Colibri
  # WEAK LOGIC PROCESS 2019
  # please note we temporary use the folder_id field to store (-1)*@survey id
  # when satisfaction will be recorded in th database, folder_id field will be recycled to store the client id
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
          @current_folder=Folder.new
          # filling all necessary fields asked by the satisfaction form
          @current_folder.id=-@survey.id
          @current_folder.poll_id=@poll.id
          @current_folder.case_number="#{@survey.description} - Client: #{@survey.client_mel} - Chargé d'affaire: #{@survey.by}"
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
      if current_user.has_ownership?(@current_folder)
        flash[:notice] = SATISFACTIONS_MSG["folder_owner"]
        redirect_to folder_path(@current_folder)
      end
      if !current_user.has_shared_access?(@current_folder)
        flash[:notice] = SATISFACTIONS_MSG["unshared_folder"]
        redirect_to root_url
      end
      if !@current_folder.is_polled?
        flash[:notice] = SATISFACTIONS_MSG["unpolled_folder"]
        redirect_to folder_path(@current_folder)
      end
      if current_user.has_completed_satisfaction?(@current_folder)
        flash[:notice] = SATISFACTIONS_MSG["already_answered"]
        redirect_to folder_path(@current_folder)
      end
      @satisfaction = Satisfaction.new
      @poll = Poll.all.find_by_id(@current_folder.poll_id)
    end
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
      if @satisfaction.folder_id < 0
        results={}
        results["affaire"]=@satisfaction.case_number
        results["date"]=@satisfaction.updated_at
        @poll=Poll.find_by_id(@satisfaction.poll_id)
        open={}
        closed={}
        opens=@poll.open_names.split(";")
        closes=@poll.closed_names.split(";");
        opens.each_with_index do |o,i|
          open["open#{i+1}"]=o.strip
        end
        closes.each_with_index do |c,i|
          closed["closed#{i+1}"]=c.strip
        end
        for j in 1..open.length
          results[open["open#{j}"]]=@satisfaction["open#{j}"]
        end
        for j in 1..closed.length
          results[closed["closed#{j}"]]=@satisfaction["closed#{j}"]
        end
        render json: results
      else        
        @current_folder = Folder.find_by_id(@satisfaction.folder_id)
        if !( current_user.has_shared_access?(@current_folder) || current_user.is_admin? )
          flash[:notice] = SATISFACTIONS_MSG["access_forbidden"]
          redirect_to root_url
        end
        @poll = Poll.find_by_id(@satisfaction.poll_id)
        render 'new'
      end
    end
  end

  ##
  # Save a satisfaction answer
  # 2 scenarios : 
  # 1) folder_id is <0, there is no link with an existing folder - the survey is independent
  #    in that case and at this stage (only), the absolute value of folder_id is temporary equal to survey_id
  # 2) folder_id is >0 and it is a classic satisfaction survey associated to an existing folder
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
            if !params[:satisfaction][:case_number].index("Client: #{client_mel}")
              render plain: "mismatch : emails have been altered"
            else
              client=Client.find_by_mel(client_mel)
              if client
                # everything should be fine at this stage - we can fix things
                # folder_id will contain (-1)*client_id
                # user_id will be (-1)*user_id of the registered user who launched the interaction
                @satisfaction.user_id = -survey.user_id
                @satisfaction.folder_id = -client.id
                if @satisfaction.save
                  survey.token="disabled#{@satisfaction.id}"
                  if survey.destroy
                    render plain: "merci d'avoir pris quelques minutes pour remplir ce sondage"
                  else
                    survey.token="disabled#{@satisfaction.id}"
                    survey.save
                    render plain: "satisfaction saved but survey not destroyed"
                  end
                else 
                  render plain: "could not save satisfaction"
                end                  
              else
                # client is not in the base
                # we save the client without fixing the organisation - it can be done further in the clients controller if needed
                client=Client.new
                client.mel=survey.client_mel
                if client.save
                  @satisfaction.user_id = -survey.user_id
                  @satisfaction.folder_id = -client.id
                  if @satisfaction.save    
                    if survey.destroy
                      render plain: "merci d'avoir pris quelques minutes pour remplir ce sondage" 
                    else
                      survey.token="disabled#{@satisfaction.id}"
                      survey.save
                      render plain: "satisfaction saved but survey not destroyed"
                    end
                  else
                    render plain: "could not save satisfaction"
                  end
                else
                  render plain: "could not save new client"
                end
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
      if @satisfaction.save
        flash[:notice] = SATISFACTIONS_MSG["satisfaction_created"]
        @poll = Poll.all.find_by_id(@satisfaction.poll_id)
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
    @poll = Poll.find_by_id(@satisfaction.poll_id)
    @satisfaction.destroy
    redirect_to poll_path(@poll)
  end

  private
    def satisfaction_params
      params.require(:satisfaction).permit(:folder_id, :poll_id, :case_number, :closed1, :closed2, :closed3, :closed4, :closed5, :closed6, :closed7, :closed8, :closed9, :closed10, :closed11, :closed12, :closed13, :closed14, :closed15, :closed16, :closed17, :closed18, :closed19, :closed20, :open1, :open2, :open3, :open4, :open5, :open6, :open7, :open8, :open9, :open10, :open11, :open12, :open13, :open14, :open15, :open16, :open17, :open18, :open19, :open20)
    end
end
