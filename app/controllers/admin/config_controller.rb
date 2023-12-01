class Admin::ConfigController < Admin::ApplicationController

  before_action :admin_auth_level_only!
  before_action :get_config
  before_action :get_parameter, except: [:index]

  def index
    @languages = Language.all
  end

  def update

    if @config.update_attributes(app_config_params)
      clear_cache
      redirect_to params[:edit] ? admin_config_edit_path(parameter: @parameter) : admin_config_path
      
    else
      flash.now[:errors] = @config.errors.full_messages
      render action: 'edit'
    end

  end

  private

  def get_config
    @config = AppConfig.get
  end

  def get_parameter
    @parameter = params[:parameter]
    redirect_to(admin_config_path) if !AppConfig.method_defined? @parameter
  end

  def app_config_params
    params.require(:app_config).permit :quality_threshold_1, :quality_threshold_2, :image_quality
  end

end