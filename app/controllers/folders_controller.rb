##
# manage folders creation within the sharebox site

class FoldersController < ApplicationController
	
  before_action :authenticate_user!
  
  ##
  # Show a complete view of all directories and files present in the application<br>
  # Only for admin users
  def index 
    unless current_user.is_admin?
      flash[:notice] = FOLDERS_MSG["index_forbidden"]
      redirect_to root_url
    end
    @parent_folders = Folder.all.where(parent_id: nil)
  end
  
  ##
  # list?id=1 json output of files and folders of a folder identified by id=1, if shared to the current_user
  # list json output of files and folders of the current_user root 
  def list
    user_id=current_user.id
    results={}
    @subfolders={}
    @assets={}
    @shared_folders_by_others={}
    if id=params[:id]
      puts("current folder request")
      current_folder=Folder.find_by_id(id)
      puts("current folder request")
      unless current_folder
        results= {folder: "inexisting folder"}
      else
        unless current_user.has_shared_access?(current_folder)
          results={folder: "insufficient rights to access this folder"}
          puts("******shared access test - FAILURE!!!!!!")
        else
          puts("******shared access test - SUCCESS!!!!!!")
          results = {current_user: user_id, folder: current_folder.name}
          @subfolders=Folder.joins(:user).where(parent_id: id).select("folders.*, users.email as owner_name, users.id as owner_id, users.statut as owner_statut")
          @assets=Asset.joins(:user).where(folder_id: id).select("assets.*, users.email as owner_name, users.id as owner_id, users.statut as owner_statut")
        end
      end
    else
      results = {current_user: user_id, folder: "user root"}
      @subfolders=current_user.folders.where(parent_id: nil)
      @assets=current_user.assets.where(folder_id: nil)
      #nearly the same as current_user.shared_folders_by_others but with more complet info on the user
      @shared_folders_by_others=SharedFolder.joins(:user).joins(:folder).select("folders.*, users.email as user_name, users.statut as statut").where(share_user_id: current_user.id).order("folders.name ASC")
    end
    #temporary exploitation
    @subfolders.each_with_index do |f,i|
      a = f.get_meta
      if a["shares"].length > 0
        metas="ce répertoire #{f.name} a des partages #{a['shares']}"
      else
        metas="ce répertoire #{f.name} n'a pas de partage"
      end
      if a["satis"].length > 0
        metas="#{metas} et a des retours satisfaction #{a['satis']}"
      else
        metas="#{metas} et n'a pas de retour satisfaction"
      end
      puts(metas)
      @subfolders[i].lists=metas
    end
    results.merge!({subfolders: @subfolders.as_json})
    results.merge!({assets: @assets.as_json})
    results.merge!({shared_folders_by_others: @shared_folders_by_others.as_json})
    render json: results
  end
  
  ##
  # Following the route /folders/:id, browse to folder @current_folder identified by id<br>
  # We check if the current user has shared access on the folder and if yes, we can go further :<br>
  # In case the current user has answered to a poll on the folder, we have to show the details of his answer<br>
  # We can consider we are waiting for the current user to express his satisfaction :<br>
  # - if current user is not the owner and is granted a share on the folder, <br>
  # - if a poll has been triggered on the folder, <br>
  # - and if the current user has not answered to the poll<br> 
  def show
    @current_folder = Folder.find_by_id(params[:id])
    if @current_folder
      if current_user.has_shared_access?(@current_folder)
        # if the user has answered to the poll, we show the details of the answer
        # if we are waiting for the current user to express his satisfaction, we redirect to new satisfaction_on_folder_path(folder)
        if @satisfaction = current_user.satisfactions.find_by_folder_id(@current_folder.id)
          redirect_to satisfaction_path(@satisfaction.id)
        elsif @current_folder.is_polled? && current_user.shared_folders_by_others.include?(@current_folder)
          puts("we move to #{new_satisfaction_on_folder_path(@current_folder)}")
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
    unless (current_user.is_admin? || current_user.is_private?)
      flash[:notice] = FOLDERS_MSG["no_folder_creation"]
      redirect_to root_url
    end
    @folder = current_user.folders.new
    if params[:folder_id]
      #@current_folder = current_user.folders.find(params[:folder_id])
      @current_folder = Folder.find_by_id(params[:folder_id])
      if @current_folder
        unless current_user.has_ownership?(@current_folder)
          flash[:notice] = FOLDERS_MSG["no_subfolder_out_of_yur_folder"]
          redirect_to root_url
        end
        @folder.parent_id = @current_folder.id
      else
        flash[:notice] = FOLDERS_MSG["no_subfolder_in_inexisting_folder"]
        redirect_to root_url
      end
    end
  end

  ##
  # Show the 'edit' form in order for the user to modify an existing folder<br>
  # Private users can only modify the folders they own<br> 
  # Modifications includes : change the name, affect a case number, trigger a poll<br>
  # please note a poll on a folder can be triggered only if the folder has been previously shared<br>
  # the owner can remove at any time the link between the poll and the folder, via the edit method of the folder controller<br>
  # **********************************************************************************************<br>
  # admins have full control on all folders created in the application but not via the edit method<br>
  # they can take full control via the moove_folder method they can use within the folders index
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
    #if ( Folder.where(case_number: @folder.case_number).length > 0 && @folder.case_number != "" ) 
    if ( Folder.find_by_case_number(@folder.case_number) && @folder.case_number != "" ) 
      flash[:notice] = FOLDERS_MSG["case_number_used"]
      if @folder.parent_id
        redirect_to folder_path(@folder.parent_id)
      else
        redirect_to root_url
      end
    else
      # if creation is a success, we redirect to the parent directory or to the root directory
      @folder.lists=@folder.initialize_meta
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
    if ( Folder.find_by_case_number(folder_params[:case_number]) && folder_params[:case_number] != "" && folder_params[:case_number] != @folder.case_number)
      flash[:notice] = FOLDERS_MSG["case_number_used"]
      if @folder.parent_id
        redirect_to folder_path(@folder.parent_id)
      else
        redirect_to root_url
      end
    else
      if @folder.update(folder_params)
      # Updating a case number on a folder also update every case number on satisfactions of the same folder
        #Satisfaction.where(folder_id: @folder.id).each do |s|
        @folder.satisfactions.each do |s|
          s.case_number = @folder.case_number
          s.save
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
  # Move a folder and/or change owner<br>
  # changing owner should be understood by fixing a new user_id for the folder and all its related objets (assets, subfolders, subassets, shares)<br>
  # This feature is only for admins<br>
  # it is basically intended for annual archiving purposes but also to architecture collaborative views between private users working together
  def moove_folder
  
    params[:id]=params[:id].to_i
    if params[:id]==0
      flash[:notice]="Préciser le numéro du répertoire à déplacer"
      redirect_to folders_path
    else
      folder_to_moove = Folder.find_by_id(params[:id])
      # we first check is the folder to move exists
      if !folder_to_moove
        flash[:notice] = "#{params[:id].to_i} #{FOLDERS_MSG["no_folder_on_that_id"]}<br>"
        redirect_to folders_path
      else
        # changeowner = 0 we do not have to fix a new user_id
        # movefolder = 0 we do not have to move the folder
        # by default, these two variables are set to 1
        changeowner = 1
        movefolder = 1
        position=params[:parent_id].to_s.index(".")
        # case 1 : we mention a new owner 
        # we must check if this destination_user_id exists
        if position
          destination_folder_id=params[:parent_id].to_s[0..position-1].to_i
          destination_user_id=params[:parent_id].to_s[position+1..-1].to_i
          unless User.find_by_id(destination_user_id)
            flash[:notice]="#{flash[:notice]} Pas d'utilisateur ayant #{destination_user_id} comme id<br>"
            changeowner = 0
          end
        # case 2 : we do not mention any new destination_user_id
        else
          destination_folder_id=params[:parent_id].to_i
        end
        destination_folder_id = nil if destination_folder_id == 0
        
        # is there an existing destination ?
        destination = Folder.find_by_id(destination_folder_id)
        if !destination && !destination_folder_id.nil?
          flash[:notice] = "#{flash[:notice]} #{destination_folder_id} #{FOLDERS_MSG["no_folder_on_that_id"]}<br>"
          movefolder = 0
        end
        
        # if we've launched a move without specifying a new owner, we'll give children to the destination folder owner
        # so we define destination_user_id equal to destination folder owner id 
        unless destination_user_id
          if destination
            destination_user_id = destination.user_id
          end
        end
        
        # is the proposed 'new owner' already the owner of the folder_to_moove ?
        if destination_user_id == folder_to_moove.user_id
          flash[:notice]="#{flash[:notice]} le répertoire appartient déjà à l'utilisateur #{destination_user_id}<br>"
          changeowner = 0
        end
        
        # is the folder_to_moove already in the proposed destination folder ?
        if folder_to_moove.parent_id == destination_folder_id
          flash[:notice] = "#{flash[:notice]} le répertoire est déjà là où vous voulez l'envoyer<br>"
          movefolder = 0
        end
        
        # we realize a move
        if movefolder == 1
          folder_to_moove.parent_id = destination_folder_id
          flash[:notice]="#{flash[:notice]} ACTION : répertoire déplacé<br>" if folder_to_moove.save
        end
        
        # we change the owner
        if changeowner == 1
          if destination_user_id
            folder_to_moove.user_id = destination_user_id
            flash[:notice]="#{flash[:notice]} ACTION : changement de propriétaire pour l'objet<br>" if folder_to_moove.save
            if folder_to_moove.children_give_to(destination_user_id)
              flash[:notice]="#{flash[:notice]} ACTION : changement de propriétaire pour les enfants<br>"
            end
          end
        end

        redirect_to folders_path
      end 
    end
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
