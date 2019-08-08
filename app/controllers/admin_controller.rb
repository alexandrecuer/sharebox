##
# The admin controller

class AdminController < ApplicationController

  before_action :authenticate_user!, :check_admin
  
  ##
  # admin controller main AUTHENTICATION
  def check_admin
    unless current_user.is_admin?
      render json: {"message": t('sb.no_permission')}
    end
  end
  
  ##
  # allow admins to take the identity of any registered user
  def become
    sign_in(:user, User.find(params[:id]))
    redirect_to root_url # or user_root_url
  end
  
  ##
  # Admin users can modify other users'status<br>
  # The 3 different status are public, private and admin<br> 
  # The first user registered on the application is considered like a super admin, his status is timeless and cannot be changed<br>
  # An admin cannot change his own status<br>
  def change_user_statut
    result={}
    unless current_user.is_admin?
      result["success"]=false
      result["message"]=t('sb.no_permission')
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
              result["message"] = "#{@user.email} (#{@user.id}) #{t('sb.new_statut')} #{@user.statut}"
            else
              result["success"]=false
              result["message"] = t('sb.error_changing_statut')
            end
          else
            result["success"]=false
            result["message"] = t('sb.own_statut_nor_superadmin_cannot_be_changed')
          end
        else
          result["success"]=false
          result["message"] = t('sb.inexisting_user')
        end
      else
        result["success"]=false
        result["message"] = t('sb.invalid_status')
      end
    end
    render json: result
  end
  
  ##
  # allows admins to assign users to groups
  def define_groups
    results={}
    unless params[:groups] && params[:groups] != ""
      results["message"]=t('sb.no_input')
    else
      user=User.find_by_id(params[:id])
      unless user
        results["message"]=t('sb.inexisting_user')
      else
        user.groups=params[:groups]
        unless user.save
          results["message"]="#{t('sb.user')} #{user.email} #{t('sb.id')} #{user.id}\n #{t('sb.notupdated')}"
        else
          results["message"]="#{t('sb.user')} #{user.email} #{t('sb.id')} #{user.id}\n #{t('sb.updated')}"
        end
      end
    end
    render json: results
  end
  
  ##
  # change the folder owner<br>
  # CAUTION !!!! <br>
  # uses the move method of the folder model, which recalculates the metadatas<br>
  # example1 : folder1 belonging to user1 contains a swarmed folder2 belonging to user2<br>
  # if we give folder1 to user3, folder2's owner is ALSO changed to user3 !!<br>
  # it is therefore necessary to recalculate/reset 'swarmed_to' in folder2's metadatas<br>
  # in this process, folder1 moves from user1's root tree to user3's root tree<br>
  # if folder1 is not a root but a swarmed folder, it stays at the same place in the tree structure but its owner is modified<br>
  # example2 : folder1 belonging to user1 contains folder2 belonging to user1<br>
  # if we give folder2 to user2, folder2 becomes swarmed
  def change_owner
    results={}
    folder=Folder.find_by_id(params[:folder_id])
    unless folder
      results["success"]=false
      results["message"]="#{t('sb.inexisting')}\n #{t('sb.folder')} #{params[:folder_id]}"
    else
      destination_user=User.find_by_id(params[:user_id])
      unless destination_user
        results["success"]=false
        results["message"]="#{t('sb.inexisting')}\n #{t('sb.user')} #{params[:user_id]}"
      else
        results=folder.move(nil,destination_user)
        folder.user_id=destination_user.id
      end
    end
    render json: results
  end
  
  ##
  # move a folder to another one or to the root if destination_folder_id is 0<br>
  # if the destination folder does not belong to the folder owner, the folder is swarmed<br>
  # possible to change the folder owner by adding ?user_id=xx<br>
  # without id -> moves the folder in the owner's root tree or swarms the folder to another user<br>
  # in folder controller, have same kind of methods with current_folder.folders.find_by_id.....to combine with drag and drop functionnalities in the browse view
  def move
    results={}
    folder=Folder.find_by_id(params[:folder_id])
    unless folder
      results["success"]=false
      results["message"]="#{t('sb.inexisting')}\n #{t('sb.folder_to_move')} #{params[:folder_id]}"
    else
      if params[:user_id]
        destination_user=User.find_by_id(params[:user_id])
        unless destination_user
          results["success"]=false
          results["message"]="#{t('sb.inexisting')}\n #{t('sb.user')} #{params[:user_id]}"
        else
          if params[:destination_folder_id].to_i==0
            results=folder.move('root',destination_user)
          else
            destination_folder=Folder.find_by_id(params[:destination_folder_id])
            unless destination_folder
              results["success"]=false
              results["message"]="#{t('sb.inexisting')}\n #{t('sb.destination_folder')} #{params[:destination_folder_id]}"
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
            results["message"]="#{t('sb.inexisting')}\n #{t('sb.destination_folder')} #{params[:destination_folder_id]}"
          else
            results=folder.move(destination_folder)
          end
        end
      end
    end
    render json: results
  end
  
  def get_env
    #####
    # this is a YAML file creation
    #entries = File.read("#{Rails.root}/.env")
    #message = "OK"
    #entries = YAML.load_file("#{Rails.root}/config/config.yml")["main"]
    #File.open("#{Rails.root}/config/test.yml","w") do |out|
    #  if out.write ("main:\n")
    #    entries.keys.each do |k|
    #      if !out.write("  #{k}: \"#{entries[k]}\"\n")
    #        message = "error in writing to the disk"
    #      end
    #    end
    #  else
    #    message = "error in writing to the disk"
    #  end
    #end
    #render plain: message
    
    # this is an attempt to manage an env file form the browser
    #ax={}
    #entries = File.read(".env").gsub("\r\n","\n").split("\n")
    #entries.each do |line|
    #  if line =~ /\A([A-Za-z_0-9]*)=(.*)\z/
    #    key=$1
    #    case val = $2
    #       when /\A'(.*)'\z/ then ax[key] = $1
    #       when /\A"(.*)"\z/ then ax[key] = $1.gsub('\n', "\n").gsub(/\\(.)/, '\1')
    #       else ax[key] = val
    #    end
    #  end
    #end
    #render json: ax
    
  end
  

end
