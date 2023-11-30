Rails.application.routes.draw do
  
  devise_for :admin_users, 
    controllers: { sessions: "admin/sessions" }, 
    path: 'admin', 
    path_names: { 
      sign_in: 'login', 
      sign_out: 'logout'
    }

  scope path: "/(:prefix)", :module => 'admin', :as => 'admin', constraints: { host: UrlHelper.host_constraint(:admin), prefix: 'admin' } do 

    post 'position' => 'application#set_position', as: :set_position
    post 'positions' => 'application#set_positions', as: :set_positions

    resources :puzzles, :path => 'puzzles/pack', except: [:index]
    delete 'puzzles/puzzle_asset/:id' => 'puzzles#delete_puzzle_asset', :path => 'puzzles/puzzle_asset', as: :delete_puzzle_asset

    resources :languages, except: [:index]
    get 'config' => 'config#index', as: :config
    get 'config/edit/:parameter' => 'config#edit', as: :config_edit
    patch 'config/edit/:parameter' => 'config#update', as: :config_update

    scope :puzzles do

      resources :packs do
        get 'toggle_published' => 'packs#toggle_published', as: :toggle_published
        get 'get_quality' => 'packs#get_quality', as: :get_quality
        get 'import_data/(:mode)' => 'packs#import_data', as: :import_data
        get 'import_images' => 'packs#import_images', as: :import_images
        get 'relink_google_sheet' => 'packs#relink_google_sheet', as: :relink_google_sheet
        get 'ping' => 'packs#check_imports', as: :ping
        get 'info' => 'packs#get_pack_info', as: :info
        get 'restore' => 'packs#restore_from_published', as: :restore_from_published
        resources :puzzle_assets, :path => 'assets', except: [:index]
      end

      scope :packs do
        post '/search' => 'packs#search', as: :search_puzzles
        get '/create_packs/:type/:number' => 'packs#create_packs', as: :create_packs
      end

      get 'puzzle_assets' => 'puzzle_assets#index', as: :puzzle_assets

      get 'generate_sprite_sheets' => 'packs#generate_sprite_sheets', as: :generate_sprite_sheets

      get 'import_data/:puzzle_id/(:mode)' => 'puzzles#import_data', as: :import_puzzle_data

      get 'apitest' => 'api_tester#index', as: :api_test

      post 'move' => 'puzzles#move', as: :puzzle_move

      get 'multi_toggle_published' => 'packs#multi_toggle_published', as: :multi_toggle_published
      get 'multi_import_data' => 'packs#multi_import_data', as: :multi_import_data
      get 'multi_import_images' => 'packs#multi_import_images', as: :multi_import_images

    end

    post 'update_pack' => 'puzzles#create_remote', as: :pack_remote
    post 'update_pack/remove_extras' => 'puzzles#create_remote_and_remove_extras', as: :pack_remote_remove_extras
    post 'update_puzzle' => 'puzzles#create_remote_puzzle', as: :pack_puzzle_remote

    get 'export_answers/:lang/(:pack_type)' => 'puzzles#export_answers', as: :export_answers
    
    get 'job_status/' => 'jobs#index', as: :jobs_status
    
    get '/auth/:provider/callback', to: 'twitter#auth'

    root 'packs#index'

  end

  scope path: "/(:prefix)", constraints: { host: UrlHelper.host_constraint(:data), prefix: 'data' } do 

    get ':api_version/puzzle(.:format)' => 'data#user_generated_puzzle', as: :user_generated_puzzle
    get ':api_version/packs_list(.:format)' => 'data#pack_list', as: :pack_get_list
    get ':api_version/packs_list_chinese(.:format)' => 'data#pack_list_chinese', as: :pack_get_list_chinese
    get ':api_version/packs/puzzle(.:format)' => 'data#pack_puzzle', as: :pack_get_puzzle
    get ':api_version/get_date' => 'data#get_server_date', as: :get_date
    get ':api_version/daily_puzzle(.:format)' => 'data#dailypuzzle', as: :daily_puzzle

  end

  root to: proc { [404, {}, ['']] }

end

