##
# User management within the sharebox site

class UsersController < ApplicationController

  before_action :authenticate_user!
  
  ## 
  # Admin users can modify other users'status<br>
  # The 3 different status are public, private and admin<br> 
  # The first user registered on the application is considered like a super admin, his status is timeless and cannot be changed<br>
  # An admin cannot change his own status<br>
  def update
    result={}
    if !current_user.is_admin?
      result["success"]=false
      result["message"]=USERS_MSG["only_for_admin"]
    else
      primo_id = User.where(statut: "admin").order("id asc").ids[0]
      valid_statuts = ["admin","private","public"]
      if valid_statuts.include?(params[:statut])
        @user = User.find_by_id(params[:id])
        if @user
          change_statut = 0
          if @current_user != @user
            change_statut = 1
          end
          if @user.id == primo_id
            change_statut = 0
          end
          if change_statut == 1
            @user.statut = params[:statut]
            if @user.save
              result["success"]=true
              result["message"] = "#{@user.email} (#{@user.id}) #{USERS_MSG["new_status"]} #{@user.statut}"
            else
              result["success"]=false
              result["message"] = USERS_MSG["error_changing_status"]
            end
          else
            result["success"]=false
            result["message"] = USERS_MSG["own_status_nor_superadmin_cannot_be_changed"]
          end
        else
          result["success"]=false
          result["message"] = USERS_MSG["inexisting_user"]
        end
      else
        result["success"]=false
        result["message"] = USERS_MSG["invalid_status"]
      end
    end
    render json: result
  end
  
  ##
  # Delete a specific user<br>
  # only for admins  
  def destroy
    if !(current_user.is_admin?)
        flash[:notice] = USERS_MSG["only_admin_may_delete_user"]
    else
        if current_user.id.to_i == params[:id].to_i
            # devise can do it but we do not integrate this feature
            flash[:notice] = USERS_MSG["yu_cannot_delete_yur_own_account"]
        else
            @user = User.find(params[:id])
            sharedto=@user.shared_folders_by_others
            puts("***************************l'utilisateur a #{sharedto.length} répertoire(s) partagé(s)")
            report=""
            if @user.destroy
              sharedto.each do |stf|
                stf.lists=stf.calc_meta
                puts("****************new meta for folder #{stf.name} are #{stf.lists}")
                unless stf.save
                  report="#{report}Ies meta données du répertoire #{stf.name} partagé à l'utilisateur supprimé n'ont pas été mises à jour\n"
                  report="#{report}Il faut lancer la mise à jour manuellement\n"
                else
                  report=report="#{report}Mise à jour des meta données du répertoire #{stf.name} partagé à l'utilisateur supprimé - OK\n"
                end
              end
              flash[:notice]="#{USERS_MSG["user"]} #{params[:id]} #{USERS_MSG["deleted"]}...#{report}"
            else 
              flash[:notice]=USERS_MSG["user_not_deleted"]
            end
        end
    end
    redirect_to users_path
  end
  
  ##
  # 1) permits to search a list of users corresponding to a given mel fragment and render to json
  # 2) Show a complete view of all users registered<br>
  #    Only for private and admin users
  def index
    if melfrag=params[:melfrag]
      allusers = User.where("email LIKE ?", "%#{melfrag}%")
      results=[]
      allusers.each do |u|
        results<< {"email": u.email,"id": u.id}
      end
      render json: results
    else
      unless current_user.is_admin?
        flash[:notice] = USERS_MSG["user_managing_forbidden"]
        redirect_to root_url
      end
    end
  end
  
  ##
  # temporary test
  def show
    users=filter(params[:groups],params[:statut],params[:melfrag],params[:order])
    render json: users.as_json(methods: ["is_sharing","has_shares"])
  end
  
  ##
  # given a word as param, return a list with the closed groups in the database 
  def get_groups
    results={}
    unless params[:groupsfrag]
      results["message"]="please provide a text"
    else
      results=User.where("groups LIKE ?","%#{params[:groupsfrag]}%").distinct.pluck(:groups)
    end
    render json: results
  end

  ##
  # private functions
  private 
    ##
    # return a list of users according to some request parameters
    # a ligth filtering function for users management
    def filter(groups=nil,statut=nil,melfrag=nil,order=nil)
      tab=[]
      request=[]
      tab[0]=""
      if groups
        unless groups=="!"
          request.push("groups like ?")
          tab.push("%#{groups}%")
        else
          request.push("(groups is null or groups = '')")
        end
      end
      if statut
        request.push("statut like ?")
        tab.push("%#{statut}%")
      end
      if melfrag
        unless melfrag.include?("!")
          request.push("email like ?")
          tab.push("%#{melfrag}%")
        else
          request.push("email not like ?")
          tab.push("%#{melfrag}%".gsub("!",""))
        end  
      end
      tab[0]=request.join(" and ")
      puts(tab)
      unless order
        order="ID ASC"
      end        
      if tab[0].length>0
        users=User.where(tab).order(order)
      else
        users=User.all.order(order)
      end
      
      #SHARING USERS
      sql = <<-SQL
        SELECT distinct users.id 
        from users 
        INNER JOIN shared_folders 
        on users.id = shared_folders.user_id;
      SQL
      sharing_users=[]
      User.find_by_sql(sql).each do |u|
        sharing_users.push(u.id)
      end
      puts("sharing users: #{sharing_users}")
      
      #USERS BEING GRANTED SHARES
      sql = <<-SQL
        SELECT distinct users.id 
        from users 
        INNER JOIN shared_folders 
        on users.id = shared_folders.share_user_id;
      SQL
      users_with_shares=[]
      User.find_by_sql(sql).each do |u|
        users_with_shares.push(u.id)
      end
      puts("users being granted shares: #{users_with_shares}")
    
      #LOOP on USERS ACTIVE RECORDS
      users.each do |u|
        if sharing_users.include?(u.id)
          u.is_sharing='offre'
        end
        if users_with_shares.include?(u.id)  
          u.has_shares='reçoit'
        end
      end
      users
    end
  
 end