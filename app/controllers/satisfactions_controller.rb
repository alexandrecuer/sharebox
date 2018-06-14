class SatisfactionsController < ApplicationController

  before_action :authenticate_user!

  def new
    # Lorsque l'on traite de satisfactions, on est forcément sur un dossier
    # La variable @shared_folders_by_others qui sert lorsque l'on est à la racine pour afficher les dossiers partagés par les autres n'est donc pas à renseigner
    # _list.html.erb n'a besoin que de @assets et de @folders

    @current_folder = Folder.find_by_id(params[:id])
    if !@current_folder
      flash[:notice] = "Vous ne pouvez pas participer à un sondage sur un répertoire qui n'existe pas "
      redirect_to root_url
    else
      if current_user.has_ownership?(@current_folder)
        flash[:notice] = " Vous ne pouvez pas participer à un sondage sur un répertoire dont vous êtes le propriétaire "
        redirect_to folder_path(@current_folder)
      end
      if !current_user.has_shared_access?(@current_folder)
        flash[:notice] = "Vous ne pouvez pas participer à un sondage sur un répertoire ne vous est pas partagé"
        redirect_to root_url
      end
      if !@current_folder.is_polled?
        flash[:notice] = "Aucune enquête en cours sur ce dossier"
        redirect_to folder_path(@current_folder)
      end
      if current_user.has_completed_satisfaction?(@current_folder)
        flash[:notice] = "Vous avez déjà répondu à une enquête sur ce répertoire"
        redirect_to folder_path(@current_folder)
      end
      @satisfaction = Satisfaction.new
      @poll = Poll.all.find_by_id(@current_folder.poll_id)
    end
  end

  # Seulement les utilisateurs privés et l'admin peuvent voir les statistiques de satisfaction
  def index 
    if current_user.is_private? || current_user.is_admin?
      @satisfactions = Satisfaction.all
      @polls = Poll.all
    else 
      flash[:notice] = "N'étant ni admin ni utilisateur privé, vous n'avez pas les droits pour accéder aux données globales de satisfaction"
      redirect_to root_url
    end
  end
  
  # Un utilisateur public peut voir les réponses d'un dossier qui lui a été partagé et qui est audité en satisfaction.
  # Il en va de même pour l'utilisateur privé et l'administrateur
  def show 
    @satisfaction = Satisfaction.find_by_id(params[:id])
    if !@satisfaction
      flash[:notice] = " Aucune enquête sous ce numéro "
      redirect_to root_url
    else
      @current_folder = Folder.find_by_id(@satisfaction.folder_id)
      if !( current_user.has_shared_access?(@current_folder) || current_user.is_admin? )
        flash[:notice] = " Vous ne pouvez accéder aux statistiques n'étant ni admin ni propriétaire ni autorisé sur ce dossier"
        redirect_to root_url
      end
      @poll = Poll.all.find_by_id(@current_folder.poll_id)
      render 'new'
    end
  end

  def create
    @satisfaction = Satisfaction.new(satisfaction_params)
    @current_folder = Folder.find_by_id(params[:satisfaction][:folder_id])
    @satisfaction.user_id = current_user.id
    if @satisfaction.save
      flash[:notice]= "Vos réponses ont été enregistrées, merci !"
      @poll = Poll.all.find_by_id(@satisfaction.poll_id)
    else
      flash[:notice]= "Error creating satisfaction."
    end
    render 'new'
  end

  def destroy
    @satisfaction = Satisfaction.find_by_id(params[:id])
    @poll = Poll.find_by_id(@satisfaction.poll_id)
    @satisfaction.destroy
    redirect_to poll_path(@poll)
  end

  private
    def satisfaction_params
      params.require(:satisfaction).permit(:folder_id, :poll_id, :case_number, :closed1, :closed2, :closed3, :closed4, :closed5, :closed6, :closed7, :closed8, :closed9, :closed10, :closed11, :closed12, :closed13, :closed14, :closed15, :closed16, :closed17, :closed18, :closed19, :closed20, :open1, :open2, :open3, :open4, :open5, :open6, :open7, :open8, :open9, :open10, :open11, :open12, :open13, :open14, :open15, :open16, :open17, :open18, :open19, :open20)
    end
end
