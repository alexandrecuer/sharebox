##
# User management within the sharebox site

class UsersController < ApplicationController

  before_action :authenticate_user!
  
  helper_method :sort_column, :sort_direction
  
  ## 
  # Admin users can modify other users'status<br>
  # The 3 different status are public, private and admin<br> 
  # The first user registered on the application is considered like a super admin, his status is timeless and cannot be changed<br>
  # An admin cannot change his own status<br>
  def update
    if !current_user.is_admin?
      flash[:notice] = USERS_MSG["only_for_admin"]
      redirect_to root_url
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
              flash[:notice] = "#{@user.email} (#{@user.id.to_s}) #{USERS_MSG["new_status"]} #{@user.statut}"
            else
              flash[:notice] = USERS_MSG["error_changing_status"]
            end
          else
            flash[:notice] = USERS_MSG["own_status_nor_superadmin_cannot_be_changed"]
          end
        else
          flash[:notice] = USERS_MSG["inexisting_user"]
        end
      else
        flash[:notice] = USERS_MSG["invalid_status"]
      end
      redirect_to users_path
    end
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
            if @user.destroy
                flash[:notice]="#{USERS_MSG["user"]} #{params[:id]} #{USERS_MSG["deleted"]}..."
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
      if current_user.is_public?
        flash[:notice] = USERS_MSG["user_managing_forbidden"]
        redirect_to root_url
      else
        @users=User.all.select("users.*, 'false' as is_sharing, 'false' as has_shares").order(sort_column + " " + sort_direction)
        #SHARING USERS
        sql = <<-SQL
          SELECT distinct users.id 
          from users 
          INNER JOIN shared_folders 
          on users.id = shared_folders.user_id;
        SQL
        sharing_users=User.find_by_sql(sql)
        sharing_users_ids = "#{sharing_users.as_json}"
        #USERS BEING GRANTED SHARES
        sql = <<-SQL
          SELECT distinct users.id 
          from users 
          INNER JOIN shared_folders 
          on users.id = shared_folders.share_user_id;
        SQL
        users_with_shares=User.find_by_sql(sql)
        users_with_shares_ids = "#{users_with_shares.as_json}"
        #LOOP on USERS ACTIVE RECORDS
        @users.each do |u|
          if /#{u.id}/.match(sharing_users_ids)
            u.is_sharing='true'
          end
          if /#{u.id}/.match(users_with_shares_ids)
            u.has_shares='true'
          end
        end
      end
    end
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
  # Functions used by the sortable method in application_helper and in the view users/index.html.erb
  # this is generating SQL requests !!!
  # a better solution should be to realize this in front office, on the client side
  private
    ##
    # Return the name of the column to sort
    def sort_column
      User.column_names.include?(params[:sort]) ? params[:sort] : "id"
    end
  
    ##
    # Return the sorting direction
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
  
 end