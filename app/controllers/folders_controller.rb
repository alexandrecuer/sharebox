##
# manage folders creation within the sharebox site

class FoldersController < ApplicationController
	
  before_action :authenticate_user!
  ##
  # Show a complete view of all directories and files present in the application<br>
  # Only for admin users
  def index 
    if !current_user.is_admin?
      flash[:notice] = FOLDERS_MSG["index_forbidden"]
      redirect_to root_url
    end
    @parent_folders = Folder.all.where(parent_id: nil)
  end
  
  ##
  # Following the route /folders/:id, browse to folder identified by id<br>
  # We check if the current user has shared access on the folder and if yes we can initialize current_folder<br>
  # if current_folder exists, we can go further :<br>
  # - In case the current user has answered to a poll on the folder, we have to show the details of his answer<br>
  # - We can consider we are waiting for the current user to express his satisfaction :<br>
  # - if current user is not the owner of the folder, 
  # - if a poll has been triggered on the folder, 
  # - and if the current user has not answered to the poll 
  def show
    folder = Folder.find_by_id(params[:id])
    if folder
      if current_user.has_shared_access?(folder)
        @current_folder = folder
      end
      if @current_folder
        # if the user has answered to the poll, we show the details of the answer
        # if we are waiting for the current user to express his satisfaction, we redirect to new satisfaction_on_folder_path(@current_folder)
        if @satisfaction = current_user.satisfactions.find_by_folder_id(@current_folder.id)
          redirect_to satisfaction_path(@satisfaction.id)
        elsif @current_folder.is_polled? && !current_user.has_ownership?(@current_folder)
          redirect_to new_satisfaction_on_folder_path(@current_folder)
        end
      else
        flash[:notice] = FOLDERS_MSG["folder_not_for_yu"]
        redirect_to root_url
      end
    else
      flash[:notice] = FOLDERS_MSG["inexisting_folder"]
      redirect_to root_url
    end
  end

  ##
  # show the 'new' form in order for the user to create a new directory<br>
  # Control if current user has got the ability to create a new folder : all public users will be rejected<br>
  # In case of a subfolder creation :<br>
  # 1) if current user browse a directory shared by another user, he will not be able to create any subfolder in it<br>
  # 2) if current user has ownership, then we fetch parent_id, in order to fill the parent_id field hidden in the form
  def new
    if !(current_user.is_admin? || current_user.is_private?)
      flash[:notice] = FOLDERS_MSG["no_folder_creation"]
      redirect_to root_url
    end
    @folder = current_user.folders.new
    if params[:folder_id]
      #@current_folder = current_user.folders.find(params[:folder_id])
      @current_folder = Folder.find_by_id(params[:folder_id])
      if @current_folder
        @folder.parent_id = @current_folder.id
        if !current_user.has_ownership?(@current_folder)
          flash[:notice] = FOLDERS_MSG["no_subfolder_out_of_yur_folder"]
          redirect_to root_url
        end
      else
        flash[:notice] = FOLDERS_MSG["no_subfolder_in_inexisting_folder"]
        redirect_to root_url
      end
    end
  end

  ##
  # Show the 'edit' form in order for the user to modify an axisting folder<br>
  # - private users can only modify the folders they own<br>
  # - admins have full control on all folders created in the application<br>
  # Modifications includes : change the name, affect a case number, trigger a poll<br>
  # please note a poll on a folder can be triggered only if the folder has been previously shared
  def edit 
    @folder = Folder.find_by_id(params[:id])
    if !@folder
      flash[:notice] = FOLDERS_MSG["inexisting_folder_cannot_be_modified"]
      redirect_to root_url
    else
      if !(current_user.has_ownership?(@folder) || current_user.is_admin?)
        flash[:notice] = FOLDERS_MSG["not_admin_nor_owner"]
        if current_user.has_shared_access?(@folder)
          redirect_to folder_path(@folder)
        else
          redirect_to root_url
        end
      else
        if @folder.parent_id
          @current_folder = Folder.find_by_id(@folder.parent_id)
        end
      end
    end
  end

  ##
  # Create a new folder<br>
  # Please note the 'new' form offers the possibility to define a case number<br>
  # This case number field can be left blank<br>
  # If not, the application will check if the given case number is already present in the database<br>
  # All non blank case numbers already used once will be rejected (usefull??)
  def create
    @folder = current_user.folders.new(folder_params)
    if ( Folder.where(case_number: @folder.case_number).length > 0 && @folder.case_number != "" ) 
      flash[:notice] = FOLDERS_MSG["case_number_used"]
      if @folder.parent_id
        redirect_to folder_path(@folder.parent_id)
      else
        redirect_to root_url
      end
    else
      # if creation is a success, we redirect to the parent directory or to the root directory
      if @folder.save
        if @folder.parent_id
          redirect_to folder_path(@folder.parent_id)
        else
          redirect_to root_url
        end
      # this permit to show all errors messages without leaving the 'new' form
      else
        if @folder.parent_id
          @current_folder = Folder.find_by_id(@folder.parent_id)
        end
        render 'new'
      end
    end
  end

  ##
  # update an existing folder<br>
  # if the user decide to modify the case number, and if this new case number is not blank, we have to check it is not already registered in the database
  def update
    @folder = Folder.find(params[:id])
    # case number update !!
    # we can get the existing case number via @folder.case_number
    # we can get the new case number via 'folder_params[:case_number]'
    if ( Folder.where(case_number: folder_params[:case_number]).length > 0 && folder_params[:case_number] != "" && folder_params[:case_number] != @folder.case_number) 
      flash[:notice] = FOLDERS_MSG["case_number_used"]
      if @folder.parent_id
        redirect_to folder_path(@folder.parent_id)
      else
        redirect_to root_url
      end
    else
      old_case_number = @folder.case_number
      if @folder.update(folder_params)
      # Updating a case number on a folder also update every case number on satisfactions of the same folder
        Satisfaction.where(case_number: old_case_number).each do |f|
          f.case_number = @folder.case_number
          f.save
        end
        if @folder.parent_id
          redirect_to folder_path(@folder.parent_id)
        else
          redirect_to root_url
        end
      else
        if @folder.parent_id
          @current_folder = Folder.find(@folder.parent_id)
        end
        render 'edit'
      end
    end
  end
  
  ##
  # destroy an existing folder
  def destroy
    @folder = current_user.folders.find(params[:id])
    activefolder=@folder.parent_id
    @folder.destroy
    flash[:notice] = FOLDERS_MSG["folder_destroyed"]
    if activefolder
      redirect_to folder_path(@folder.parent_id)
    else
      redirect_to root_url
    end
  end

  ##
  # Move a folder<br>
  # This feature is only for admins and is intended for annual archiving purposes
  def moove_folder
    folder_to_moove = Folder.find_by_id(params[:id])

    if folder_to_moove
      if params[:parent_id] == "0" 
        # On déplace le répertoire à la racine 
        folder_to_moove.parent_id = nil
        folder_to_moove.save
      else
        if Folder.find_by_id(params[:parent_id])
          # On déplace le répertoire parent dans un autre
          folder_to_moove.parent_id = params[:parent_id]
          folder_to_moove.user_id = Folder.find_by_id(params[:parent_id]).user_id
          folder_to_moove.save
          # on vérifie l'arborescence
          if folder_to_moove.has_sub_asset_or_share?
            folder_to_moove.get_subs_assets_shares.each do |c|
              c.user_id = folder_to_moove.user_id
              c.save
            end
          end
        else
          flash[:notice] = (params[:parent_id]).to_s + FOLDERS_MSG["no_folder_on_that_id"]
        end
      end
    else
      flash[:notice] = (params[:id]).to_s + FOLDERS_MSG["no_folder_on_that_id"]
    end
    redirect_to folders_path
  end

  ##
  # Manage the route /folders/:folder_id/new<br>
  # If a user try to use such a route, an error message will be returned 
  def error
    flash[:notice]= FOLDERS_MSG["not_a_proper_new_folder_route"]
    redirect_to folder_path(params[:folder_id])
  end


  private
    def folder_params
      params.require(:folder).permit(:name, :parent_id, :poll_id, :case_number, :id)
    end
end
