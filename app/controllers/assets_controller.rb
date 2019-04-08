## 
# manage assets'creation inside the sharebox site

class AssetsController < ApplicationController

before_action :authenticate_user!
  
  def index
    assets=Asset.all
    render json: assets
  end
  
  ## 
  # Method used when following the route /assets/assets_id<br>
  # Show the name of the file and its directory (forge/attachments/asset_id/asset_name)<br>
  # actually not used.... 
  def show
    if @asset = current_user.assets.find_by_id(params[:id])
        render json: @asset
    else
        render json: {id: false, message:"inexisting asset or no right on that asset"}
    end
  end
  
  ##
  # Show the new form in order to upload a new asset<br>
  # method used when following a route /folders/folder_id/new_file or /assets/new<br>
  # /folders/folder_id/new_file will upload the asset in the folder identified by folder_id<br>
  # /assets/new will upload the asset at the root of the user - such files are strictly personal and cannot be shared<br>  
  # Only admin or private users are able to upload files<br>
  # They cannot upload files outside the folders they own
  def new
    unless (current_user.is_admin? || current_user.is_private?)
      flash[:notice] = ASSETS_MSG["rights_missing"]
      redirect_to root_url
    end
    @asset = current_user.assets.new
    # If there is a folder_id, we attach the file to the corresponding folder<br>
    # if not, ir will be a root located file 
    if params[:folder_id]
      @current_folder = current_user.folders.find_by_id(params[:folder_id])
      if @current_folder
        @asset.folder_id = @current_folder.id
      else
        flash[:notice] = "Cette action n'est pas autorisée<br>"
        flash[:notice] = "#{flash[:notice]} - #{ASSETS_MSG["inexisting_folder"]}<br>"
        flash[:notice] = "#{flash[:notice]} - #{ASSETS_MSG["not_yur_folder"]}"
        redirect_to root_url
      end
    end
  end
  
  def upload_asset
      results={}
      if params[:asset][:folder_id]==""
        params[:asset][:folder_id]=nil
      end
      if current_user.is_private? || current_user.is_admin?
          unless Folder.find_by_id(params[:asset][:folder_id]) || params[:asset][:folder_id].nil?
            results["success"]=false
            results["message"]="impossible de poursuivre - vous essayez de charger un fichier dans un répertoire inexistant"
          else
	        asset = current_user.assets.new(asset_params)
            if asset.save
              results["success"]=true
              results["message"]="fichier mis en ligne"
            else
              results["success"]=false
              result="échec de la mise en ligne\n"
              result="#{result}type non autorisé ou taille trop importante"
              results["message"]=result
            end
          end
      else
          results["success"]=false
          results["message"]="vous ne pouvez pas mettre en ligne de fichiers"
      end
      render json: results
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
          @current_folder = current_user.folders.find_by_id(@asset.folder_id)
        end
        render 'new'
      end
  end
  
  def delete_asset
    results={}
    if asset = current_user.assets.find_by_id(params[:id])
      if asset.destroy
        results["success"]=true
        results["message"]="fichier supprimé"
      else
        results["success"]=false
        results["message"]="impossible de supprimer le fichier"
      end
    else
      results["success"]=false
      results["message"]= "ce fichier n'existe pas ou ne vous appartient pas"
    end
    render json: results
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
  def get
    #asset = current_user.assets.find_by_id(params[:id])
    asset = Asset.find_by_id(params[:id])
    
    if asset
      #case 1 : asset is a root file
      if !asset.folder_id
        if current_user.has_asset_ownership?(asset)
          get_file(asset)
        else
          flash[:notice] = ASSETS_MSG["asset_not_for_yu"]
          redirect_to root_url
        end
      else
        #case 2 : asset belongs to a directory
        current_folder = Folder.find_by_id(asset.folder_id)
        if current_user.has_shared_access?(current_folder)
          #using the shared_folders message field to track file openings from a given share on folder
          if @shared_folder = SharedFolder.find_by_share_user_id_and_folder_id(current_user.id,asset.folder_id)
            n = @shared_folder.message.to_i + 1
            puts("*******trying to download a file from share number #{@shared_folder.id}")
            puts("*******tracked #{n} access from that share !!")
            @shared_folder.message= n
            @shared_folder.save
          end
          get_file(asset)
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
    
    ##
    # private method for file opening management<br>
    # 2 different options for file storage are possible :<br>
    # - 1) local storage in application_root/forge/attachments/<br>
    # - 2) Amazon S3 mode, in a cloud storage<br>
    # asset will be stored in a directory named with the asset id : asset_id/asset_name
    def get_file(asset)
      # switching to S3, we use "redirect_to asset.uploaded_file.expiring_url(10)"
      # this creates a valid 10s url that allows access to private S3 files
      if Rails.application.config.local_storage==1
        puts ("opening local file")
        send_file asset.uploaded_file.path, :type => asset.uploaded_file_content_type
      elsif Rails.application.config.local_storage==0
        puts ("opening amazon S3 file")
        redirect_to asset.uploaded_file.expiring_url(10)
      end
    end
end
