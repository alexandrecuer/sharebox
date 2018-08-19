## 
# manage assets'creation inside the sharebox site

class AssetsController < ApplicationController

before_action :authenticate_user!
  
  ## 
  # Method used when following the route /assets/assets_id<br>
  # Show the name of the file and its directory (forge/attachments/asset_id/asset_name)
  def show
    @asset = current_user.assets.find(params[:id])
  end
  
  ##
  # Show the new form in order to upload a new asset<br>
  # method used when following a route /folders/folder_id/new_file or /assets/new<br>
  # /folders/folder_id/new_file will upload the asset in the folder identified by folder_id<br>
  # /assets/new will upload the asset at the root of the user - such files are strictly personal and cannot be shared<br>  
  # Only admin or private users are able to upload files<br>
  # They cannot upload files outside the folders they own
  def new
    if !(current_user.is_admin? || current_user.is_private?)
      flash[:notice] = ASSETS_MSG["rights_missing"]
      redirect_to root_url
    end
    @asset = current_user.assets.new
    # If there is a folder_id, we attach the file to the corresponding folder<br>
    # if not, ir will be a root located file 
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
  # following the call to the new asset method, upload an asset and register it in the database<br>
  # if the asset is a root file, we redirect to root else we redirect to the parent folder
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
  # Destroy the asset<br>
  # only for owners - to be fixed
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
  # Permits the user to download a file<br>
  # 2 different options for file storage are possible :<br>
  # - 1) local storage in application_root/forge/attachments/<br>
  # - 2) Amazon S3 mode, in a cloud storage<br>
  # asset will be stored in a directory named with the asset id : asset_id/asset_name
  def get
    #asset = current_user.assets.find_by_id(params[:id])
    asset = Asset.find_by_id(params[:id])
    
    if asset
      #case 1 : asset is a root file
      if !asset.folder_id
        if current_user.has_asset_ownership?(asset)
          # switching to S3, we use "redirect_to asset.uploaded_file.expiring_url(10)"
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
