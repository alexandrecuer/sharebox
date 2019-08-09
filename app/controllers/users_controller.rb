##
# User management within the sharebox site

class UsersController < ApplicationController

  before_action :authenticate_user!
  
  ## 
  # update current user preferences : lang and groups
  def update
    unless current_user.id == params[:id].to_i
      flash[:notice] = t('sb.no_permission')
      message="___________________________________________#{params[:id]} vs #{current_user.id}"
      puts("\e[31m#{message}\e[0m")
      redirect_to root_url
    else
      if current_user.update(params.require(:user).permit(:lang,:groups))
        I18n.locale=params[:user][:lang]
        flash[:notice]=t('sb.updated')
      else
        flash[:notice]=t('sb.not_updated')
      end
    end
    redirect_to user_path(params[:id])
  end
  
  ##
  # Delete a specific user<br>
  # only for admins  
  def destroy
    unless current_user.is_admin?
        flash[:notice] = t('sb.only_admin_may_delete_user')
    else
        if current_user.id.to_i == params[:id].to_i
            # devise can do it but we do not integrate this feature
            flash[:notice] = t('sb.yu_cannot_delete_yur_own_account')
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
                  report="#{report} #{t('sb.folder_metas')} #{stf.name} #{t('sb.shared_to_the_deleted_user')}\n"
                  report="#{report} #{t('sb.not_updated')}\n"
                  report="#{report} #{t('sb.please_ask_admin_to_update_manually')}\n"
                else
                  report="#{report} #{t('sb.folder_metas')} #{stf.name} #{t('sb.shared_to_the_deleted_user')}\n"
                  report="#{report} #{t('sb.updated')}\n"
                end
              end
              flash[:notice]="#{t('sb.user')} #{params[:id]} #{t('sb.deleted')}...#{report}"
            else 
              flash[:notice]="#{t('sb.user')} #{params[:id]} #{t('sb.not_deleted')}"
            end
        end
    end
    redirect_to users_path
  end
  
  ##
  # Search a list of users according to some filtering parameters and render to json<br>
  # params are melfrag, statut, groups<br>
  # if param admin is present, calculates also the sharing practises which are not recorded in the database<b>
  # possible to add a param order (not finalized)
  # please note in a controller, params always exists - its minimal size is 2 with 2 keys : controller and action<br>
  # if params has got only two keys, render the users management dashboard
  def index
    color_code="33"
    puts ("\e[#{color_code}m**********we are in the controller #{params[:controller]}\e[0m")
    puts ("\e[#{color_code}m**********params has got #{params.keys.length} key(s)\e[0m")
    puts ("\e[#{color_code}m**********which are : #{params.keys}\e[0m")
    
    #if melfrag=params[:melfrag]
    if params.keys.length>2
      #allusers = User.where("email LIKE ?", "%#{melfrag}%")
      #results=[]
      #allusers.each do |u|
      #  results<< {"email": u.email,"id": u.id}
      #end
      #render json: results
      #users=filter(params[:groups],params[:statut],params[:melfrag],params[:order])
      users=filter(params)
      if params[:admin]
        render json: users.as_json(methods: ["is_sharing","has_shares"])
      else
        render json: users
      end
    else
      unless current_user.is_admin?
        flash[:notice] = t('sb.no_permission')
        redirect_to root_url
      end
    end
  end
  
  ##
  # user's preference dashboard<br>
  # permits to set the locale and the groups
  def show
    @user=current_user
  end
  
  
  ##
  # given a word as param, return a list with the closed groups in the database 
  def get_groups
    results={}
    unless params[:groupsfrag]
      results["message"]=t('sb.no_input')
    else
      results=User.where("groups LIKE ?","%#{params[:groupsfrag]}%").distinct.pluck(:groups)
    end
    render json: results
  end

  ##
  # private functions
  private 
  
    ##
    # generate where part of the request
    def wherestring(params)
      groups=params[:groups]
      statut=params[:statut]
      melfrag=params[:melfrag]
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
      tab
    end

    ##
    # define in the users records, extra fields related to sharing and receiving    
    def fixpractises(users)
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
          u.is_sharing=t('sb.is_sharing')
        end
        if users_with_shares.include?(u.id)  
          u.has_shares=t('sb.has_shares')
        end
      end
      users
    end
    
    ##
    # return a list of users according to some request parameters
    # a ligth filtering function for users management
    #def filter(groups=nil,statut=nil,melfrag=nil,order=nil)
    def filter(params)
      tab=wherestring(params)
      order=params[:order]
      unless order
        order="ID ASC"
      end        
      if tab[0].length>0
        users=User.where(tab).order(order)
      else
        users=User.all.order(order)
      end
      if params[:admin]
        users=fixpractises(users)
      end
      users
    end
  
 end