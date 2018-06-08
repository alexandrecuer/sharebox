class HomeController < ApplicationController

before_action :authenticate_user!

	def update
		if !current_user.is_admin?
			flash[:notice] = "Seul les admins peuvent changer le statut des utilisateurs"
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
							flash[:notice] = "Erreur lors du changement de statut"
						end
					else
						flash[:notice] = "Vous ne pouvez pas changer votre propre statut ou celui du super administrateur"
					end
				else
					flash[:notice] = "Vous ne pouvez pas changer le statut d'un utilisateur inexistant"
				end
			else
				flash[:notice] = "Statut invalide"
			end
			redirect_to list_path
		end
	end
    
    def list 
    	@users=User.all
    	if current_user.is_public?
      		flash[:notice] = "Les utilisateurs publics ne peuvent ni visualiser ni gérer les autres utilisateurs"
      		redirect_to root_url
    	end
    end 

    def destroy
    	redirect_to root_url
    end
end