class Admin::LanguagesController < Admin::ApplicationController

  before_action :admin_auth_level_only!

  def new
    @language = Language.new
    @url = admin_languages_path
    add_breadcrumb 'New Language'
  end

  def create
    
    @language = Language.new language_params

    if @language.save
      clear_cache
      redirect_to params[:edit] ? edit_admin_language_path(id: @language.id) : admin_config_path
    else
      flash.now[:errors] = @language.errors.full_messages
      render action: 'new'
    end
  end

  def edit

    begin
      @language = Language.find params[:id]
    rescue
      return redirect_to admin_root_path
    end

    @url = admin_language_path(id: @language.id)
    add_breadcrumb @language.name
    
  end

  def update

    begin
      @language = Language.find params[:id]
    rescue
      return redirect_to admin_root_path
    end

    if @language.update_attributes(language_params)
      clear_cache
      redirect_to params[:edit] ? edit_admin_language_path(id: @language.id) : admin_config_path
      
    else
      @url = admin_language_path(id: @language.id)
      flash.now[:errors] = @language.errors.full_messages
      render action: 'edit'
    end

  end

  def destroy

    begin
      @language = Language.find params[:id]
    rescue
      return redirect_to admin_root_path
    end
    
    if @language.destroy
      redirect_to admin_config_path
    else
      flash.now[:errors] = @language.errors.full_messages
      render action: 'edit'
    end

  end

  private

  def language_params
    params.require(:language).permit :name, :code
  end

end


