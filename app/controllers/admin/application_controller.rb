class Admin::ApplicationController < ActionController::Base

  before_filter :authenticate_admin_user!
  before_filter :admin_auth_level_only!, only: [:set_positions, :set_position]
  before_filter :get_app_config

  layout 'admin'

  def tag_hints

    tags = (params[:q] == '') ? [] : ActsAsTaggableOn::Tag.where("LOWER(name) LIKE '#{params[:q].downcase}%'").collect{ |t| t.name }.sort!

    respond_to do |format|
      format.json do
        render :json => { :status => :error } if !params[:q]
        render :json => { :status => :OK, :tags => tags }
      end
    end

  end

  def clear_cache
    Rails.cache.clear
  end

  protected

  def get_app_config
    @config = AppConfig.get
  end

  def json_error errors, status=400
    render json: { errors: errors }, status: status
  end

  def admin_auth_level_only!
    if current_admin_user && current_admin_user.auth_level != 'admin'
      return redirect_to admin_user_generated_puzzles_path
    end
  end

  def refresh_pack_zip

    if @pack
      pack = @pack
    elsif @puzzle
      pack = @puzzle.pack
    end

    PackOps.delay.refresh_zip pack if pack

  end

  def refresh_game_positions
    PackOps.delay.refresh_pack_puzzle_game_positions
  end

  def get_languages
    
    @languages = Language.all
    
    if @pack
      if @pack.is_chinese
        @languages = Language.chinese
      else
        @languages = Language.not_chinese
      end
    end

  end

  def get_cookies

    if cookies[:sync_prefs].nil? || cookies[:sync_prefs]['content'].nil? || cookies[:sync_prefs]['language'].nil?
      @sync_prefs = {'content' => 'all', 'language' => @languages.collect(&:code)}
    else 
      @sync_prefs = JSON.parse(cookies[:sync_prefs])
    end

  end

  
end
