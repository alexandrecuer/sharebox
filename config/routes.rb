Rails.application.routes.draw do

  resources :assets
  resources :folders
  resources :shared_folders
  resources :satisfactions
  resources :polls
  
  devise_for :users
  
   # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
   root to: "home#index"
   
   get "forge/get/:id" => "assets#get", :as => "download"
   
   get "forge/get/:id/:filename" => "assets#get", :as => "downloadb"
   
   get "folders/:folder_id/new_file" => "assets#new", :as => "new_sub_asset"
   
   get "folders/:folder_id/new_folder" => "folders#new", :as => "new_sub_folder"
   
   get "listusers" => "home#list", :as => "list"
   
   get "shared_folders/:id/new" => "shared_folders#new", :as => "new_share_on_folder"

   # vu que l'URI assets/new permet de potser un nouveau fichier à la racine
   # si un utilisateur modifie l'URI en assets/folder_id/new il faut que celà déclenche la même action que folders/folder_id/new_file
   get "assets/:folder_id/new" => "assets#new", :as => "new_sub_assetb"
   
   # vu que l'URI folders/new permet de créer un nouveau répertoire à la racine
   # si un utilisateur modifie l'URI en folders/folder_id/new 
   # il faut renvoyer un message d'erreur du type new what ? folder or file
   get "folders/:folder_id/new" => "folders#error", :as => "error"
   
   # complete missing share_user_id (suid)
   get "complete_suid" => "shared_folders#complete_suid", :as => "complete_suid"

   get "folders/:id/satisfaction" => "satisfactions#new", :as => "new_satisfaction_on_folder"
   
   patch '/listusers' => 'home#update', :as => 'update_user'

   patch '/folders' => 'folders#moove_folder', :as => 'moove_folder'

   get "shared_folders/:id/email" => "shared_folders#send_email", :as => "send_email"

end
