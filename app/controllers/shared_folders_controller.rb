class SharedFoldersController < ApplicationController

  before_action :authenticate_user!
  
  def show
    @shared_folders = current_user.shared_folders.where("folder_id = "+params[:id]) 
    @current_folder = current_user.folders.find(params[:id])

    @satisfactions = Satisfaction.where(folder_id: @current_folder.id)
    @poll = Poll.find_by_id(@current_folder.poll_id)
  end

  #TODO
  #cette méthode sert a mettre à jour la base manuellement lorsque des utilisateurs s'inscrivent
  #si un user s'est vu attribuer des partages avant d'exister, les share_user_id correspondant dans la table share_folders sont vides
  #à la création de l'user, un after_create (cf model user.rb) se charge de renseigner les share_user_id
  #probablement à évacuer
  def complete_suid
    current_user.complete_suid
    if current_user.set_admin
      flash[:notice] = current_user.email + " root/admin"
    end
    redirect_to root_url
  end

  def new
    @to_be_shared_folder = Folder.find_by_id(params[:id])
    if !current_user.has_ownership?(@to_be_shared_folder)
      flash[:notice] = "Vous ne pouvez pas partager un répertoire qui n'existe pas ou ne vous appartient pas"  
      redirect_to root_url
    else
      @shared_folder = current_user.shared_folders.new
      @current_folder = @to_be_shared_folder.parent
    end
  end

  def create
    flash[:notice]=""
    emails=params[:shared_folder][:share_email]
    if emails == "" 
      flash[:notice]="Il faut indiquer une adresse mel"
    else
      email_addresses = emails.split(",")
      # 12/02/2018 : on met en test le processus d'envoi un mel à l'admin pour l'informer des partages réalisés
      # ceci n'est utile que dans un premier temps - il faudra probablement évacuer cette fonctionnalité par la suite
      # mel_text est le corps du message mel contenant la liste des partages effectivement réalisés
      mel_text=""
      email_addresses.each do |email_address|
        if email_address == current_user.email
          flash[:notice] = "Vous avez déjà accès à ce répertoire"
        else
          email_address=email_address.delete(' ')
          @shared_folder = current_user.shared_folders.new(shared_folder_params)
          @shared_folder.share_email = email_address
          #on cherche si l'email existe dans la table des utilisateurs
          #s'il n'y est pas, on devra mettre à jour le champ share_user_id après l'inscription 
          share_user = User.find_by_email(email_address)
          @shared_folder.share_user_id = share_user.id if share_user
          exist = current_user.shared_folders.where("share_email = '"+email_address+"' and folder_id = "+params[:shared_folder][:folder_id])
          if exist.length >0
            flash[:notice]+="Partage déjà opérationnel pour l'adresse : " + email_address + "<br>"
          else
            if @shared_folder.save
              a="Partage effectué pour l'adresse : " + email_address + "<br>"
              flash[:notice]+=a
              mel_text+=a
            else
              flash[:notice]+="Il n'a pas été possible de partager le répertoire vers l'adresse : " + email_address + "<br>"
            end
          end
        end
      end
      #si mel_text existe, alors on envoie le mel
      if mel_text != ""
        #UserMailer.inform_admin(current_user,mel_text).deliver_now
        #TODO
        #utilisation de active jobs
        #il faudra mettre en place un adapter de type sidekiq avec base de données clé valeur REDIS
        #on utilise les méthodes perform_now ou perform_later
        mel_text="Partage du répertoire "+params[:shared_folder][:folder_id]+"<br>"+mel_text
        InformAdminJob.perform_now(current_user,mel_text)
      end
    end
    # on sort du formulaire de partage (app/views/shared_folders/_form.html.erb)
    # l'id du répertoire que l'on vient de partager est donné par params[:shared_folders][:folder_id]
    @folder = current_user.folders.find(params[:shared_folder][:folder_id])
    if @folder.parent_id
      redirect_to folder_path(@folder.parent_id)
    else
      redirect_to root_url
    end
  end
  
  def destroy
    # on arrive içi via une URI de type shared_folders/id avec la méthode DELETE
    # donc params[:id] donne l'id de la folder pour laquelle on veut supprimer tous les partages
    @shared_folders = current_user.shared_folders.where("folder_id = "+params[:id])
    @folder = current_user.folders.find(params[:id])
    
    @shared_folders.each do |f|
      f.destroy
    end
    flash[:notice] = "Vous venez de supprimer tous les partages sur ce répertoire !"
    
    if @folder.parent_id
      redirect_to folder_path(@folder.parent_id)
    else
      redirect_to root_url
    end
  end

  def edit
    @to_be_unshared_folder = Folder.find_by_id(params[:id])
  end

  def delete
    params[:emails].each do |email|
      SharedFolder.destroy(shared_email: email)
    end
  end

  def send_email
    shared_folder = SharedFolder.find_by_id(params[:id])
    InformUserJob.perform_now(shared_folder.share_email)
    redirect_to shared_folder_path(shared_folder.folder_id)
  end

  private
    def shared_folder_params
      params.require(:shared_folder).permit(:share_email, :share_user_id, :folder_id, :message)
    end
  
 end