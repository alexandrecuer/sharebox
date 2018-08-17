##
# User managing within the sharebox site

class HomeController < ApplicationController

  before_action :authenticate_user!

  helper_method :sort_column, :sort_direction

  ## 
  # Admin users can modify other users'status
  # 3 differents status are public, private and admin. 
  # The first user registered on the application is considered like a super admin, his status cannot be changed
  # An admin cannot change his own status 
  def update
    if !current_user.is_admin?
      flash[:notice] = HOME_MSG["only_for_admin"]
      redirect_to list_path
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
              flash[:notice] = @user.email + '('+@user.id.to_s+') a désormais le statut :'+@user.statut
            else
              flash[:notice] = HOME_MSG["error_changing_status"]
            end
          else
            flash[:notice] = HOME_MSG["own_statut_nor_superadmin_cannot_be_changed"]
          end
        else
          flash[:notice] = HOME_MSG["inexisting_user"]
        end
      else
        flash[:notice] = HOME_MSG["invalid_status"]
      end
      redirect_to list_path
    end
  end
    
  ##
  # Show a complete view of all users registered on the application
  # Only for private and admin users
  def list 
    @users=User.all.order(sort_column + " " + sort_direction)
    if current_user.is_public?
      flash[:notice] = HOME_MSG["user_managing_forbidden"]
      redirect_to root_url
    end
  end

  ##
  # Allow to delete users, later ? 
  def destroy
    redirect_to root_url
  end

  # Functions intended for the sortable method in application_helper
  private
    ##
    # Return the sorting direction
    def sort_column
      User.column_names.include?(params[:sort]) ? params[:sort] : "id"
    end
  
    ##
    # Return the name of the column to sort
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
end