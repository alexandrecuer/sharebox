##
# User managing within the sharebox site

class UsersController < ApplicationController

  before_action :authenticate_user!
  
  ##
  # Delete a specific user<br>
  # only for admins  
  def destroy
    if !(current_user.is_admin?)
        flash[:notice] = "Vous devez être administrateur pour supprimer un utilisateur"
    else
        if current_user.id.to_i == params[:id].to_i
            flash[:notice] = "Vous ne pouvez supprimer votre propre compte"
        else
            @user = User.find(params[:id])
            if @user.destroy
                flash[:notice]="Utilisateur "+params[:id]+" supprimé..."
            else 
                flash[:notice]="Echec de la suppression"
            end
        end
    end
    redirect_to list_path
  end
  
 end