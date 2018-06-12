class AssetsController < ApplicationController

before_action :authenticate_user!

  def index
  end
  
  def show
    @asset = current_user.assets.find(params[:id])
  end
  
  def new
    if !(current_user.is_admin? || current_user.is_private?)
      flash[:notice] = "Vous ne pouvez pas mettre en ligne de fichier"
      redirect_to root_url
    end
    @asset = current_user.assets.new
    # soit on a un folder_id - cf routage new_sub_asset - l'URI va être de type /folders/folder_id/new_file
    # soit on n'en a pas et on met en ligne le fichier à la racine
    if params[:folder_id]
      @current_folder = Folder.find_by_id(params[:folder_id])
      if @current_folder
        @asset.folder_id = @current_folder.id
        if !current_user.has_ownership?(@current_folder)  
            flash[:notice] = "Vous ne pouvez mettre en ligne de fichier que dans les répertoires vous appartenant"
            redirect_to root_url
        end
      else
        flash[:notice] = "Vous ne pouvez pas mettre en ligne de fichier dans un répertoire qui n'existe pas"
        redirect_to root_url
      end
    end
    
  end
  
  def create
    # pour la définition de asset_params, voir les private methods en fin de ce fichier controller 
	  @asset = current_user.assets.new(asset_params)
      # soit la mise en ligne est un succès et on renvoie soit vers le répertoire de l'asset, soit vers la racine 
      if @asset.save
        flash[:notice] = "Mise en ligne réussie!"
        if @asset.folder_id
          redirect_to folder_path(@asset.folder_id)
        else
          redirect_to root_url
        end
        # soit la mise en ligne est un échec...
      else
        if @asset.folder_id
          @current_folder = Folder.find_by_id(@asset.folder_id)
        end
        render 'new'
      end
	
  end
  
  def destroy
    @asset = current_user.assets.find(params[:id])
    @asset.destroy
    flash[:notice] = "Suppression réussie!"
    if @asset.folder_id
      redirect_to folder_path(@asset.folder_id)
    else
      redirect_to root_url
    end
  end
  
  def get
    #asset = current_user.assets.find_by_id(params[:id])
    asset = Asset.find_by_id(params[:id])
    
    if asset
      #case 1 : asset is a root file
      if !asset.folder_id
        if current_user.has_asset_ownership?(asset)
          #en passant à S3, on utilise redirect_to asset.uploaded_file.expiring_url(10)
          #celà crée une url valable 10s qui permet d'accéder à des fichiers S3 privés
          #send_file asset.uploaded_file.path, :type => asset.uploaded_file_content_type
          redirect_to asset.uploaded_file.expiring_url(10)
        else
          flash[:notice] = "Ce fichier ne vous appartient pas ou ne vous est pas destiné !"
          redirect_to root_url
        end
      else
        #case 2 : asset belongs to a directory
        current_folder = Folder.find_by_id(asset.folder_id)
        if current_user.has_shared_access?(current_folder)
          #passage à S3
          #send_file asset.uploaded_file.path, :type => asset.uploaded_file_content_type
          redirect_to asset.uploaded_file.expiring_url(10)
        else
          flash[:notice] = "Ce fichier ne vous appartient pas ou ne vous est pas destiné !"
          redirect_to root_url
        end
      end
    else
      flash[:notice] = "Ce fichier n'existe pas !"
      redirect_to root_url
    end
  end
  
  private
    def asset_params
      params.require(:asset).permit(:uploaded_file, :folder_id)
      # previous config when form was only composed of a file input
      #params.require(:asset).permit(:uploaded_file, :folder_id) if params[:asset]
    end
end
