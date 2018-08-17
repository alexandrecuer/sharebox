## 
# manage assets creation inside folders within the sharebox site

class AssetsController < ApplicationController

before_action :authenticate_user!
  
  ## A view accessible via "/assets/assets_id"
  # You can find the name of the file and where he is saved (forge/attachments//asset_id/asset_name)
  def show
    @asset = current_user.assets.find(params[:id])
  end
  
  ##
  # Only admin or private users are able to download files on the application
  # They cannot download files inside folder they don't own
  def new
    if !(current_user.is_admin? || current_user.is_private?)
      flash[:notice] = ASSETS_MSG["rights_missing"]
      redirect_to root_url
    end
    @asset = current_user.assets.new
    # If there is a folder_id, then the path will be like : /folders/folder_id/new_file
    # Else the file will be located at the root 
    if params[:folder_id]
      @current_folder = Folder.find_by_id(params[:folder_id])
      if @current_folder
        @asset.folder_id = @current_folder.id
        if !current_user.has_ownership?(@current_folder)  
            flash[:notice] = ASSETS_MSG["not_yur_folder"]
            redirect_to root_url
        end
      else
        flash[:notice] = ASSETS_MSG["inexisting_folder"]
        redirect_to root_url
      end
    end
  end
  
  ##
  # When an asset is created on the application, 
  # if the asset is located at the root, we send back to root 
  # else we send back to the folder that contain the file
  def create
	  @asset = current_user.assets.new(asset_params)
      if @asset.save
        flash[:notice] = ASSETS_MSG["asset_uploaded"]
        if @asset.folder_id
          redirect_to folder_path(@asset.folder_id)
        else
          redirect_to root_url
        end
      else
        if @asset.folder_id
          @current_folder = Folder.find_by_id(@asset.folder_id)
        end
        render 'new'
      end
  end
  
  ##
  # Every file can be deleted by the user who own it 
  def destroy
    @asset = current_user.assets.find(params[:id])
    @asset.destroy
    flash[:notice] = ASSETS_MSG["asset_destroyed"]
    if @asset.folder_id
      redirect_to folder_path(@asset.folder_id)
    else
      redirect_to root_url
    end
  end
  

  ##
  # This method explain how the files are saved on the application, there is 2 differents possibilities :
  # - 1) The file is saved in a directory following a path like : (forge/attachments//asset_id/asset_name)
  # - 2) Amazon S3 mode : The file is saved in a cloud storage
  def get
    #asset = current_user.assets.find_by_id(params[:id])
    asset = Asset.find_by_id(params[:id])
    
    if asset
      #case 1 : asset is a root file
      if !asset.folder_id
        if current_user.has_asset_ownership?(asset)
          # switching to S3, we use "redirect_to asset.uploaded_file.expiring_url(10)""
          # this creates a valid 10s url that allows access to private S3 files
          #send_file asset.uploaded_file.path, :type => asset.uploaded_file_content_type
          redirect_to asset.uploaded_file.expiring_url(10)
        else
          flash[:notice] = ASSETS_MSG["asset_not_for_yu"]
          redirect_to root_url
        end
      else
        #case 2 : asset belongs to a directory
        current_folder = Folder.find_by_id(asset.folder_id)
        if current_user.has_shared_access?(current_folder)
          # switch to S3
          #send_file asset.uploaded_file.path, :type => asset.uploaded_file_content_type
          redirect_to asset.uploaded_file.expiring_url(10)
        else
          flash[:notice] = ASSETS_MSG["asset_not_for_yu"]
          redirect_to root_url
        end
      end
    else
      flash[:notice] = ASSETS_MSG["inexisting_asset"]
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
