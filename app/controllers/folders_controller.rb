class FoldersController < ApplicationController

  before_action :authenticate_user!
  
  #uniquement pour la gestion du routage de type /folders/folder_id/new
  # si un utilisateur envoie une URI de ce type, il faut lui renvoyer un message d'erreur
  def error
    flash[:notice]="new what ? new_folder ? new_file ?"
    redirect_to folder_path(params[:folder_id])
  end

  # Index permet d'afficher l'arborescence des dossiers pour les utilisateurs admin
  def index 
    if !current_user.is_admin?
      flash[:notice] = "Vous n'avez pas accès à cette page"
      redirect_to root_url
    end
    @parent_folders = Folder.all.where(parent_id: nil)
  end
  
  def show
    folder = Folder.find_by_id(params[:id])
    if folder
      if current_user.has_shared_access?(folder)
        @current_folder = folder
      end
      if @current_folder
        # Si l'utilisateur en cours a déjà répondu à l'enquête satisfaction, on affiche sa réponse
        # S'il n'a pas répondu et qu'il se trouve :
        # 1) que le répertoire est audité en satisfaction,
        # 2) et que l'user en cours n'est pas le propriétaire, 
        # alors c'est que l'user en cours est interrogé satisfaction (vu qu'il a shared_access - current_folder existe)
        # donc on fait un redirect_to new_satisfaction_on_folder_path(@current_folder)
        if @satisfaction = current_user.satisfactions.find_by_folder_id(@current_folder.id)
          redirect_to satisfaction_path(@satisfaction.id)
        elsif @current_folder.is_polled? && !current_user.has_ownership?(@current_folder)
          redirect_to new_satisfaction_on_folder_path(@current_folder)
        end
      else
        flash[:notice] = "Ce répertoire ne vous appartient pas, ne vous est pas destiné !"
        redirect_to root_url
      end
    else
      flash[:notice] = "Ce répertoire n'existe pas !"
      redirect_to root_url
    end
  end
  
  def new
    if !(current_user.is_admin? || current_user.is_private?)
      flash[:notice] = "Vous ne pouvez pas créer de dossier"
      redirect_to root_url
    end
    @folder = current_user.folders.new
    # soit on crée un sous-répertoire dans un répertoire : sub_folder
    # 1) the folder form integrates a parent_id field we have to fill at this stage
    # 2) if we are in a shared_by_others directory, we cannot create any sub directory
    if params[:folder_id]
      #@current_folder = current_user.folders.find(params[:folder_id])
      @current_folder = Folder.find_by_id(params[:folder_id])
      if @current_folder
        @folder.parent_id = @current_folder.id
        if !current_user.has_ownership?(@current_folder)
          flash[:notice] = "Vous ne pouvez créer de sous répertoire que dans les répertoires vous appartenant"  
          redirect_to root_url
        end
      else
        flash[:notice] = "Vous ne pouvez pas créer de sous répertoire dans un répertoire qui n'existe pas"
        redirect_to root_url
      end
    end
  end
  
  def create
    @folder = current_user.folders.new(folder_params)
    # Un numéro d'affaire est unique, mais on peut créer plusieurs dossiers sans préciser de numéro d'affaire
    if ( Folder.where(case_number: @folder.case_number).length > 0 && @folder.case_number != "" ) 
      flash[:notice] = "Ce numéro d'affaire existe déjà"
      if @folder.parent_id
        redirect_to folder_path(@folder.parent_id)
      else
        redirect_to root_url
      end
    else
      # soit la création du répertoire est un succès et on renvoie vers le répertoire parent ou vers la racine
      if @folder.save
        if @folder.parent_id
          redirect_to folder_path(@folder.parent_id)
        else
          redirect_to root_url
        end
      # Cette seconde partie du if permet, sans que l'utilisateur ait le sentiment de changer de page de porter à sa connaissance 
      # les messages d'erreur et de réafficher le formulaire au cas ou le processus de création serait un échec. 
      else
        if @folder.parent_id
          @current_folder = Folder.find_by_id(@folder.parent_id)
        end
        render 'new'
      end
    end
  end
  
  def destroy
    @folder = current_user.folders.find(params[:id])
    activefolder=@folder.parent_id
    @folder.destroy
    flash[:notice] = "Suppression réussie!"
    if activefolder
      redirect_to folder_path(@folder.parent_id)
    else
      redirect_to root_url
    end
  end

  # L'admin peut modifier tous les dossiers, même ceux qui ne lui sont pas partagés
  def edit 
    @folder = Folder.find_by_id(params[:id])
    if !@folder
      flash[:notice] = "Vous ne pouvez pas apporter de modifications à un répertoire qui n'existe pas"
      redirect_to root_url
    else
      if !(current_user.has_ownership?(@folder) || current_user.is_admin?)
        flash[:notice] = "Vous n'êtes pas propriétaire ou administrateur"
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

  def update
    @folder = Folder.find(params[:id])
    # On accède au nouveau numéro d'affaire via 'folder_params[:case_number]'
    # On s'assure de 3 choses : 
    # Si on ne modifie pas le numéro d'affaire c'est ok 
    # Si on modifie le numéro d'affaire et que le nouveau numéro n'existe pas déjà c'est ok 
    # Si le nouveau numéro d'affaire est vide alors c'est ok 
    if ( Folder.where(case_number: folder_params[:case_number]).length > 0 && folder_params[:case_number] != "" && folder_params[:case_number] != @folder.case_number) 
      flash[:notice] = "Ce numéro d'affaire existe déjà"
      if @folder.parent_id
        redirect_to folder_path(@folder.parent_id)
      else
        redirect_to root_url
      end
    else
      old_case_number = @folder.case_number
      if @folder.update(folder_params)
      # En mettant à jour un numéro d'affaire sur un dossier, on met à jour toutes les satisfactions du dossier
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
          if folder_to_moove.has_childrens?
            childrens = folder_to_moove.get_childrens
            childrens.each do |children|
              children.user_id = folder_to_moove.user_id
              children.save
            end
          end
        else
          flash[:notice] = "Le second id ne correspond à aucun répertoire"
        end
      end
    else
      flash[:notice] = "Le premier id ne correspond à aucun répertoire"
    end
    redirect_to folders_path
  end


  private
    def folder_params
      params.require(:folder).permit(:name, :parent_id, :poll_id, :case_number)
    end
end
