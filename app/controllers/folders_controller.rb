class FoldersController < ApplicationController

  before_action :authenticate_user!
  
  #uniquement pour la gestion du routage de type /folders/folder_id/new
  # si un utilisateur envoie une URI de ce type, il faut lui renvoyer un message d'erreur
  def error
  flash[:notice]="new what ? new_folder ? new_file ?"
  redirect_to folder_path(params[:folder_id])
  end
  
  def show
    folder = Folder.find_by_id(params[:id])
    if folder
        if current_user.has_shared_access?(folder)
            @current_folder = folder
        end
        if @current_folder
            @folders = @current_folder.children
            @assets = @current_folder.assets.order("uploaded_file_file_name desc")
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
    @folder = current_user.folders.new
    # soit on crée un sous-répertoire dans un répertoire : sub_folder
    # dans ce cas, on un folder_id - cf routage new_sub_folder - l'URI par laquelle on arrive içi est de type /folders/folder_id/new_file
    # soit on en a pas et on crée un répertoire à la racine via une URI de type folders/new
    # *******************************************************************************
    # 1) the folder form integrates a parent_id field we have to fill at this stage
    # 2) if we are in a shared_by_others directory, we cannot create any sub directory
    if params[:folder_id]
      #@current_folder = current_user.folders.find(params[:folder_id])
      @current_folder = Folder.find_by_id(params[:folder_id])
      if @current_folder
        @folder.parent_id = @current_folder.id
        @assets = @current_folder.assets.order("uploaded_file_file_name desc")
        @folders = @current_folder.children
        if !current_user.has_ownership?(@current_folder)
            flash[:notice] = "Vous ne pouvez créer de sous répertoire que dans les répertoires vous appartenant"  
            redirect_to root_url
        end
      else
        flash[:notice] = "Vous ne pouvez pas créer de sous répertoire dans un répertoire qui n'existe pas"
        redirect_to root_url
      end
      
    # on est à la racine 
    # l'URI est de type /folders/new
    # on doit afficher la racine donc les assets et les folders de la racine et les folders qui lui sont partagées
    else
      @folders=current_user.folders.roots
      @assets=current_user.assets.where("folder_id is NULL").order("uploaded_file_file_name desc")
      @shared_folders_by_others=current_user.shared_folders_by_others
    end
  end
  
  def create
	@folder = current_user.folders.new(folder_params)
    # soit la création du répertoire est un succès et on renvoie vers le répertoire parent ou vers la racine
	if @folder.save
      if @folder.parent_id
        redirect_to folder_path(@folder.parent_id)
      else
        redirect_to root_url
      end
    else
      if @folder.parent_id
        @current_folder = Folder.find_by_id(@folder.parent_id)
        @assets = @current_folder.assets.order("uploaded_file_file_name desc")
        @folders = @current_folder.children
      else
        @folders=current_user.folders.roots
        @assets=current_user.assets.where("folder_id is NULL").order("uploaded_file_file_name desc")
        @shared_folders_by_others=current_user.shared_folders_by_others
      end
      render 'new'
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
  
  private
    def folder_params
	  params.require(:folder).permit(:name, :parent_id)
    end
end
