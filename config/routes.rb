Rails.application.routes.draw do

 #scope "(:locale)", locale: /fr|en/ do
  resources :assets
  resources :folders
  resources :shared_folders
  resources :satisfactions
  resources :polls
  resources :surveys
  resources :clients
  
  devise_for :users, :path_prefix => 'my'
  
  resources :users
  
   # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
   root to: "home#index"
   
   get "forge/get/:id" => "assets#get", :as => "download"
   
   get "forge/get/:id/:filename" => "assets#get", :as => "downloadb"
   
   get "folders/:folder_id/new_file" => "assets#new", :as => "new_sub_asset"
   
   get "folders/:folder_id/new_folder" => "folders#new", :as => "new_sub_folder"
   
   get "shared_folders/:id/new" => "shared_folders#new", :as => "new_share_on_folder"

   # vu que l'URI assets/new permet de poster un nouveau fichier à la racine
   # si un utilisateur modifie l'URI en assets/folder_id/new il faut que celà déclenche la même action que folders/folder_id/new_file
   get "assets/:folder_id/new" => "assets#new", :as => "new_sub_assetb"
   
   # vu que l'URI folders/new permet de créer un nouveau répertoire à la racine
   # si un utilisateur modifie l'URI en folders/folder_id/new 
   # il faut renvoyer un message d'erreur du type new what ? folder or file
   get "folders/:folder_id/new" => "folders#error", :as => "error"
   
   # complete missing share_user_id (suid)
   get "complete_suid" => "shared_folders#complete_suid", :as => "complete_suid"

   get "folders/:id/satisfaction" => "satisfactions#new", :as => "new_satisfaction_on_folder"

   patch '/folders' => 'folders#moove_folder', :as => 'moove_folder'
   
   get "getpolls" => "surveys#getpolls", :as => "getpolls"
   
   get "surveys/:id/md5/:md5" => "satisfactions#freenew", :as => "new_satisfaction_no_folder"
   
   get "freelist" => "satisfactions#freelist", :as => "freelist"
   
   get "list" => "folders#list", :as => "list"
   
   get "help" => "help#index", :as => "help"
   
   get "browse" => "folders#browse", :as => "browse"
   
   post "upload_asset" => "assets#upload_asset", :as => ""
   
   delete "delete_asset/:id" => "assets#delete_asset", :as => ""
   
   post "update_folder" => "folders#update_folder", :as => "update_folder"
   
   post "share" => "shared_folders#share", :as => "share"
   
   get "getshares/:folder_id" => "shared_folders#getshares", :as => "getshares"
   
   delete "deleteshare/:folder_id/:id" => "shared_folders#deleteshare", :as => "deleteshare"
   
   get "satisfactions/json/:id" => "satisfactions#json", :as => "satisfaction_json"
   
   post "create_folder" => "folders#create_folder", :as => ""
   
   delete "delete_folder/:id" => "folders#delete_folder", :as => ""
   
   get "check/:id" => "folders#check", :as => ""
   
   get "become/:id" => "admin#become", :as => "become"
   
   get "contact_customer/:folder_id" => "shared_folders#contact_customer", :as => ""
   
   get "move/:folder_id/:destination_folder_id" => "admin#move", :as => ""
   
   get "change_owner/:folder_id/:user_id" => "admin#change_owner", :as => ""
   
   get "feedback/:satisfaction_id" => "satisfactions#feedback", :as => ""
   
   get "feedback_metas" => "satisfactions#feedback_metas", :as => ""
   
   post "define_groups" => "admin#define_groups", :as => ""
   
   get "get_groups" => "users#get_groups", :as => ""
   
   get "satisfactions/run/:poll_id" => "satisfactions#run", :as => ""
   
   get "surveys/:poll_id/fill_empty_metas" => "surveys#fill_empty_metas", :as => ""
   
   get "i18n" => "help#i18n", :as => "i18n"
 #end

end
