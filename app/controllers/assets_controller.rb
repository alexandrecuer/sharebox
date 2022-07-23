##
# manage assets'creation inside the sharebox site

class AssetsController < ApplicationController

  before_action do
    :authenticate_user!
    # cf https://stackoverflow.com/questions/51110789
    #activestorage-service-url-rails-blob-path-cannot-generate-full-url-when-not-u?rq=1
    ActiveStorage::Current.host = request.base_url
  end

  def index
    # request preparation
    req=prepare_attached_docs_request
    fullreq=[]

    unless params[:folder_id]
        fullreq[0]=req.join("")
        fullreq.push('Asset')
        assets=Asset.find_by_sql(fullreq)
    else
        req.push(" and assets.folder_id = ?")
        fullreq[0]=req.join("")
        fullreq.push('Asset')
        fullreq.push(params[:folder_id])
        assets=Asset.find_by_sql(fullreq)
    end
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
        render json: {id: false, message:"#{t('sb.inexisting')} - #{t('sb.no_permission')}"}
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
      flash[:notice] = t('sb.no_permission')
      redirect_to root_url
    end
    @asset = current_user.assets.new
    # If there is a folder_id, we attach the file to the corresponding folder<br>
    # if not, it will be a root located file
    if params[:folder_id]
      @hosting_folder = current_user.folders.find_by_id(params[:folder_id])
      if @hosting_folder
        @asset.folder_id = @hosting_folder.id
      else
        flash[:notice] = t('sb.no_permission')
        flash[:notice] = "#{flash[:notice]} - #{t('sb.inexisting_folder')}<br>"
        flash[:notice] = "#{flash[:notice]} - #{t('sb.folder_not_for_yu')}"
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
            results["message"]="#{t('sb.stop')} - #{t('sb.inexisting_folder')}"
          else
	        asset = current_user.assets.new(asset_params)
            if asset.save
              results["success"]=true
              results["message"]=t('sb.uploaded')
            else
              results["success"]=false
              result="#{t('sb.not_uploaded')}\n"
              result="#{result}#{t('sb.size_or_type_problem')}"
              results["message"]=result
            end
          end
      else
          results["success"]=false
          results["message"]=t('sb.no_permission')
      end
      render json: results
  end

  ##
  # following the call to the new asset method, upload an asset and register it in the database<br>
  # if the asset is a root file, we redirect to root else we redirect to the parent folder
  def create
      @asset = current_user.assets.new(asset_params)
      if @asset.save
        flash[:notice] = t('sb.uploaded')
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
        results["message"]=t('sb.deleted')
      else
        results["success"]=false
        results["message"]=t('sb.not_deleted')
      end
    else
      results["success"]=false
      results["message"]= "#{t('sb.inexisting')} - #{t('sb.no_permission')}"
    end
    render json: results
  end

  ##
  # Destroy the asset<br>
  # only for owners - to be fixed
  def destroy
    @asset = current_user.assets.find(params[:id])
    @asset.destroy
    flash[:notice] = t('sb.deleted')
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
          flash[:notice] = t('sb.no_permission')
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
          flash[:notice] = t('sb.no_permission')
          redirect_to root_url
        end
      end
    else
      flash[:notice] = t('sb.inexisting')
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
    # - 1) local storage in application_root/storage/<br>
    # - 2) Amazon S3 mode, in a cloud storage<br>
    def get_file(asset)
      redirect_to url_for(asset.uploaded_file)
    end
end
