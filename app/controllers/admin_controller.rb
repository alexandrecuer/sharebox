##
# The admin controller

class AdminController < ApplicationController

  before_action :authenticate_user!, :check_admin
  
  ##
  # admin controller main AUTHENTICATION
  def check_admin
    unless current_user.is_admin?
      render json: {"message": "forbidden access"}
    end
  end
  
  ##
  # allow admins to take the identity of any registered user
  def become
    sign_in(:user, User.find(params[:id]))
    redirect_to root_url # or user_root_url
  end
  
  ##
  # allows admins to assign users to groups
  def define_groups
    results={}
    unless params[:groups]
      results["message"]="no information provided"
    else
      user=User.find_by_id(params[:id])
      unless user
        results["message"]="inexisting user"
      else
        user.groups=params[:groups]
        unless user.save
          results["message"]="could not save the user"
        else
          results["message"]="user #{user.email} number #{user.id}\n groups modified to #{params[:groups]}"
        end
      end
    end
    render json: results
  end
  
  ##
  # change the folder owner<br>
  # CAUTION !!!! <br>
  # uses the move method of the folder model, which recalculates the metadatas<br>
  # example : folder1 belonging to user1 contains a swarmed folder2 belonging to user2<br>
  # if we give folder1 to user3, folder2's owner is ALSO changed to user3 !!<br>
  # it is necessary to recalculate/reset 'swarmed_to' in folder2's metadatas
  def change_owner
    results={}
    folder=Folder.find_by_id(params[:folder_id])
    unless folder
      results["success"]=false
      results["message"]="le répertoire dont vous voulez changer le propriétaire n'existe pas"
    else
      destination_user=User.find_by_id(params[:user_id])
      unless destination_user
        results["success"]=false
        results["message"]="l'utilisateur de destination n'existe pas"
      else
        results=folder.move(nil,destination_user)
        folder.user_id=destination_user.id
      end
    end
    render json: results
  end
  
  ##
  # move a folder to another one or to the root if destination_folder_id is 0<br>
  # if the derstination folder does not belong to the folder owner, the folder is swarmed<br>
  # possible to change the folder owner by adding ?user_id=xx<br>
  def move
    results={}
    folder=Folder.find_by_id(params[:folder_id])
    unless folder
      results["success"]=false
      results["message"]="le répertoire que vous voulez déplacer n'existe pas"
    else
      if params[:user_id]
        destination_user=User.find_by_id(params[:user_id])
        unless destination_user
          results["success"]=false
          results["message"]="l'utilisateur de destination n'existe pas"
        else
          if params[:destination_folder_id].to_i==0
            results=folder.move('root',destination_user)
          else
            destination_folder=Folder.find_by_id(params[:destination_folder_id])
            unless destination_folder
              results["success"]=false
              results["message"]="le répertoire de destination n'existe pas"
            else
              results=folder.move(destination_folder,destination_user)
            end
          end
        end
      else
        if params[:destination_folder_id].to_i==0
          results=folder.move('root')
        else
          destination_folder=Folder.find_by_id(params[:destination_folder_id])
          unless destination_folder
            results["success"]=false
            results["message"]="le répertoire de destination n'existe pas"
          else
            results=folder.move(destination_folder)
          end
        end
      end
    end
    render json: results
  end
  

  end
