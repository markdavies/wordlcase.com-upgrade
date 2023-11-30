class Admin::PacksController < Admin::ApplicationController
  include UrlHelper
  include AdminHelper

  before_filter :admin_auth_level_only!
  before_filter :set_parent_breadcrumb
  before_filter :get_multi_ids, only: [:multi_import_images, :multi_toggle_published, :multi_import_data]
  after_filter :flash_notice, :only => [:update, :create]
  after_filter :refresh_pack_zip, :only => [:update, :create, :destroy, :do_refresh_pack_zip]
  after_filter :refresh_game_positions, :only => [:update, :create, :destroy]

  def index
    @packs = Pack.filter params[:filter]
    @invalid_packs = Pack.invalid
    get_languages
    get_cookies
  end

  def new
    @pack = Pack.new
    @url = admin_packs_path
    add_breadcrumb 'New Puzzle Pack'
  end

  def create
    
    @pack = Pack.new pack_params

    if @pack.save
      clear_cache
      redirect_to params[:edit] ? edit_admin_pack_path(id: @pack.id) : admin_packs_path
    else
      flash.now[:errors] = @pack.errors.full_messages
      render action: 'new'
    end
  end

  def edit

    begin
      @pack = Pack.find params[:id]
    rescue
      return redirect_to admin_root_path
    end

    @url = admin_pack_path(id: @pack.id)

    get_languages
    get_cookies

    add_breadcrumb @pack.pack_code
    
  end

  def update

    begin
      @pack = Pack.find params[:id]
    rescue
      return redirect_to admin_root_path
    end

    if @pack.update_attributes(pack_params)
      
      @pack.update_status_column
      clear_cache
      redirect_to params[:edit] ? edit_admin_pack_path(id: @pack.id) : admin_packs_path
      
    else
      
      @url = admin_pack_path(id: @pack.id)
      flash.now[:errors] = @pack.errors.full_messages
      render action: 'edit'

    end

  end

  def destroy

    begin
      @pack = Pack.find params[:id]
    rescue
      return redirect_to admin_root_path
    end
    
    if @pack.destroy
      redirect_to admin_packs_path
    else
      flash.now[:errors] = @pack.errors.full_messages
      render action: 'edit'
    end

  end

  def toggle_published

    @pack = Pack.find params[:pack_id]

    if @pack.is_publishable

      @pack.published = !@pack.published
      @pack.save
      
      @pack.update_status_column
      
      @pack.delayed_parcel_process

    end
    
    redirect_to edit_admin_pack_path(id: @pack.id)

  end

  def get_quality

    get_languages

    pack = Pack.find params[:pack_id]
    config = AppConfig.get

    quality = @languages.collect do |language|
      pack.quality(language.code)
    end

    render :json => {
      quality: quality,
      quality_threshold_1: config.quality_threshold_1,
      quality_threshold_2: config.quality_threshold_2
    }

  end

  def import_data

    @pack = Pack.find params[:pack_id]
    @pack.delayed_data_import params[:content], params[:language]

    redirect_to edit_admin_pack_path(id: @pack.id)

  end

  def import_images

    @pack = Pack.find params[:pack_id]
    @pack.delayed_images_import

    redirect_to edit_admin_pack_path(id: @pack.id)

  end

  def restore_from_published

    restored = 0

    @pack = Pack.find params[:pack_id]

    @pack.pack_puzzles.each do |puzzle|
      
      if !puzzle.puzzle_published.blank?
        puzzle.update_column(:puzzle, puzzle.puzzle_published)
        restored = restored + 1
      end

    end

    flash[:notices] = ["Restored #{restored} puzzles"]

    @pack.update_status_column
    @pack.update_modified_at_time

    redirect_to edit_admin_pack_path(id: @pack.id)

  end

  def multi_import_images

    if @packs
      
      @packs.each do |pack|
        pack.delayed_images_import
      end

      flash[:notices] = ["Importing images for #{@packs.length} packs"]

    end

    redirect_to admin_packs_path

  end

  def multi_toggle_published

    published = 0
    unpublished = 0

    if @packs
      
      @packs.each do |pack|

        if pack.is_publishable

          pack.published = !pack.published
          pack.save

          published = published + 1 if pack.published
          unpublished = unpublished + 1 if !pack.published
          
          pack.update_status_column
          pack.delayed_parcel_process

        end

      end

      flash[:notices] = ["#{published} published, #{unpublished} unpublished"]

    end

    redirect_to admin_packs_path

  end

  def multi_import_data

    if @packs
      
      @packs.each do |pack|
        pack.delayed_data_import params[:content], params[:language]
      end

      flash[:notices] = ["Importing data for #{@packs.length} packs"]

    end

    redirect_to admin_packs_path

  end

  def check_imports

    @pack = Pack.find params[:pack_id]

    render :json => { 
      data_processing: @pack.data_processing,
      images_processing: @pack.images_processing,
      parcel_processing: @pack.parcel_processing,
      draft_parcel_processing: @pack.draft_parcel_processing
    }

  end

  def get_pack_info

    @pack = Pack.find params[:pack_id]
    puzzles = @pack.pack_puzzles.collect do |p|
      {
        id: p.id, 
        image_id: p.image_id, 
        position: p.position
      }
    end

    render :json => {
      puzzles: puzzles
    }

  end

  def generate_sprite_sheets
    PackOps.set_sprite_sheet_status 'refreshing'
    PackOps.delay.generate_all_sprite_sheets
    redirect_to admin_packs_path
  end

  def search

    if params[:q]
      @searched = params[:q]
      @pack_puzzles = PackPuzzle.search(@searched)
      @invalid_packs = Pack.invalid
      @languages = Language.all
    end

    render action: 'index'

  end

  def create_packs

    if [Pack::TYPE_DAILY, Pack::TYPE_CLASSIC, Pack::TYPE_CHINESE, Pack::TYPE_SPECIAL].include?(params[:type])
      
      number = params[:number].to_i
      
      if [1, 10].include?(number)
        
        PackOps.bulk_create_packs(params[:type], number)

        flash[:notices] = ["#{number} #{params[:type]} pack #{number > 1 ? 's' : ''} created"]

      end

    end

    redirect_to admin_packs_path

  end

  def relink_google_sheet

      @pack = Pack.find params[:pack_id]
      result = DataImporter.relink_to_google_sheet @pack

      if result
        flash[:notices] = ["Successfully relinked to Google Sheets"]
      else
        flash[:notices] = ["Unable to relink to Google Sheets"]
      end

      redirect_to edit_admin_pack_path(id: @pack.id)
      
  end

  private

  def set_parent_breadcrumb
    add_breadcrumb 'Puzzle Packs', admin_packs_path
  end

  def pack_params
    params.require(:pack).permit :pack_code, :extra_data, :tested_primary, :published, :required_app_version, pack_puzzle_positions: []
  end

  def flash_notice
    if !@pack.flash_alert.blank?
      flash[:errors] = [@pack.flash_alert]
    end
  end

  def get_multi_ids
    
    ids = params[:ids].split(',').collect(&:to_i)
    
    if ids.length > 0
      @packs = Pack.where(id: ids)
    else
      @packs = nil
    end

  end

end


