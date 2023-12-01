require 'open-uri'

class Admin::PuzzlesController < Admin::ApplicationController

  include AdminHelper

  before_action :admin_auth_level_only!
  before_action :authenticate_admin_user!, except: [:create_remote, :create_remote_and_remove_extras]
  before_action :add_title_breadcrumb, except: [:daily, :search]

  after_action :refresh_pack_zip, :only => [:update, :create, :destroy, :create_remote, :create_remote_and_remove_extras, :create_remote_puzzle]
  after_action :refresh_game_positions, :only => [:update, :create, :destroy, :create_remote, :create_remote_and_remove_extras, :create_remote_puzzle]

  protect_from_forgery with: :null_session, only: [:create_remote, :create_remote_and_remove_extras]


  def new

    @puzzle = PackPuzzle.new
    @packs = Pack.all
    @pack = Pack.find(params[:pack_id])

    if @pack
      @puzzle.position = @pack.pack_puzzles.length
      @puzzle.pack = @pack
    end

    get_languages

    @puzzle_asset = PuzzleAsset.new

    @url = admin_puzzles_path
    add_breadcrumb 'New Puzzle'

  end

  def create

    @puzzle = PackPuzzle.new puzzle_params

    if puzzle_params[:puzzle] && puzzle_params[:puzzle] != ''
      parsed_params = puzzle_params_no_language
    else
      parsed_params = puzzle_params
    end

    @puzzle.update_attributes(parsed_params)
    @success = @puzzle.save
    
    if @success

      @puzzle.pack.update_status_column
      @puzzle.pack.match_assets

      clear_cache
      redirect_to puzzle_redirect_path(@puzzle)

    else
      flash.now[:errors] = @puzzle.errors.full_messages
      @url = admin_puzzles_path

      @puzzle_asset = PuzzleAsset.new
      @pack = Pack.find(puzzle_params[:pack_id])
      get_languages

      render action: 'new'
    end

  end

  def create_remote
    do_remote_pack_update false
  end

  def create_remote_and_remove_extras
    do_remote_pack_update true
  end

  def create_remote_puzzle
    do_remote_puzzle_update
  end

  def edit

    begin
      @puzzle = PackPuzzle.find(params[:id])
    rescue
      return redirect_to admin_root_path
    end

    @url = admin_puzzle_path(id: @puzzle.id)
    
    @pack = @puzzle.pack
    @packs = Pack.where('pack_code != ?', @pack.pack_code)
    
    get_languages
    get_cookies

    @puzzle_asset = @puzzle.puzzle_asset || PuzzleAsset.new
    
    add_breadcrumb @pack.pack_code, edit_admin_pack_path(id: @pack.id)
    add_breadcrumb @puzzle.image_id

  end

  def show
    @puzzle = PackPuzzle.find(params[:id])
    render json: @puzzle.puzzle_or_fail(false)
  end

  def update
    
    begin
      @puzzle = PackPuzzle.find(params[:id])
    rescue
      return redirect_to admin_root_path
    end

    if @puzzle.puzzle != puzzle_params[:puzzle]
      parsed_params = puzzle_params_no_language
    else
      parsed_params = puzzle_params
    end

    @url = admin_puzzle_path(id: @puzzle.id)

    if @puzzle.update_attributes(parsed_params)

      @puzzle.save
      @puzzle.pack.match_assets
      @puzzle.pack.update_column(:published, false)
      @puzzle.pack.update_status_column

      position = params[:pack_puzzle][:position].to_i

      PackPuzzle.set_position(@puzzle.id, position) if position != @puzzle.position

      clear_cache
      redirect_to puzzle_redirect_path(@puzzle)

    else
      flash.now[:errors] = @puzzle.errors.full_messages
      render action: 'edit'
    end
  end

  def destroy

    begin
      @puzzle = PackPuzzle.find(params[:id])
    rescue
      return redirect_to admin_root_path
    end

    pack = @puzzle.pack

    result = pack.pack_puzzles.destroy(@puzzle)

    if result
      if pack
        pack.update_status_column
        redirect_to edit_admin_pack_path(id: pack.id)
      else
        redirect_to admin_daily_puzzles_path
      end
    else
      flash.now[:errors] = @puzzle.errors.full_messages
      render action: 'edit'
    end
  end

  def delete_puzzle_asset

    puzzle_asset = PuzzleAsset.find(params[:id])
    redirect_path = edit_admin_pack_path(id: puzzle_asset.pack.id)

    puzzle_asset.destroy

    redirect_to redirect_path

  end

  def search

    add_breadcrumb 'Search'

    if params[:q]
      @searched = params[:q]
      @results = PackPuzzle.search(@searched)
    end

  end

  def import_data

    @puzzle = PackPuzzle.find params[:puzzle_id]
    DataImporter.delay.import_for_puzzle @puzzle, params[:content], params[:language]
    PackOps.delay.refresh_zip @puzzle.pack
    PackOps.set_sprite_sheet_status 'stale'
    @puzzle.data_processing = true
    @puzzle.save

    redirect_to edit_admin_puzzle_path(id: @puzzle.id)

  end

  def move

    @puzzle = PackPuzzle.find params[:puzzle_id]
    @target = PackPuzzle.find params[:target_id]
    action_type = params[:action_type]

    if !@puzzle || !@target || !['move-before', 'move-after', 'swap'].include?(action_type)
      status = 1
      message = "Cannot find that puzzle"

    else

      pack_id = @puzzle.pack_id
      position = @puzzle.position
      target_pack_id = @target.pack_id
      target_position = @target.position

      puzzle_asset_file = @puzzle.puzzle_asset.image.url(:original)
      target_asset_file = @target.puzzle_asset.image.url(:original) if action_type == 'swap'

      if action_type == 'swap'

        @puzzle.pack_id = target_pack_id
        @puzzle.position = target_position

        @puzzle.puzzle_asset.pack_id = target_pack_id
        @puzzle.puzzle_asset.move_and_reprocess_image

        @puzzle.save
        @puzzle.puzzle_asset.save

        @target.pack_id = pack_id
        @target.position = position

        @target.puzzle_asset.pack_id = pack_id
        @target.puzzle_asset.move_and_reprocess_image
        
        @target.save
        @target.puzzle_asset.save

        @puzzle.pack.delayed_parcel_process
        @target.pack.delayed_parcel_process

      else

        @puzzle.pack_id = target_pack_id

        @puzzle.puzzle_asset.pack_id = target_pack_id
        @puzzle.puzzle_asset.move_and_reprocess_image

        @puzzle.save
        @puzzle.puzzle_asset.save

        @puzzle.pack.delayed_parcel_process

        pos = action_type == 'move-before' ? target_position : target_position + 1

        PackPuzzle.set_position(@puzzle.id, pos)

        status = 0
        message = "Puzzle moved"

      end

    end

    render json: {status: status, message: message }

  end

  def export_answers

    require 'csv'

    lang_code = params[:lang]
    pack_type = params[:pack_type]
    words_captions = PackOps.get_words_and_captions_for_lang(lang_code, pack_type)

    csv = CSV.generate do |csv|

      words_captions.each_with_index do |item, index|

        item[:answers].each_with_index do |answer, answer_index|
          ar = [item[:game_position], answer]
          ar << item[:caption] if item[:caption] && answer_index == 0
          csv << ar
        end

      end
    end

    filename = "answers-#{lang_code}"
    filename << "-#{pack_type}" if pack_type
    filename << ".csv"

    respond_to do |format|
      format.csv { send_data csv, filename: filename }
    end

  end

  private

  def do_remote_pack_update remove_extras

    status = 0
    message = "success"

    if params[:password] != ENV['REMOTE_ACCESS_PASSWORD']
      status = 1
      message = "unauthorised"
    end

    pack = Pack.find_by_pack_code params[:pack_id]
    
    if pack.nil?
      status = 1
      message = "No pack with that ID"
      modified = nil
    end

    uploaded_puzzles = JSON.parse(params[:puzzles]) rescue false

    if uploaded_puzzles === false
      status = 1
      message = "Puzzle data is invalid"
      modified = nil
    end
    
    if status == 0

      uploaded_puzzles.each_with_index do |puzzle, index|
        
        p = pack.existing_or_new_puzzle_by_position(index)

        p.puzzle = puzzle.to_json
        p.sanitize_imported_data
        p.extract_data_from_json
        p.position = index

        res = p.save

      end

      pack.modified_at = Time.now
      pack.published = false

      extras = (pack.pack_puzzles.length - uploaded_puzzles.length)

      if remove_extras && extras > 0

        extra_puzzles = pack_puzzles.last(extras)
        pack_puzzles.destroy(extra_puzzles)

      end

      pack.save
      
      pack.match_assets
      modified = pack.modified_at.to_time.to_i

      @pack = pack

    end
    
    render json: {status: status, message: message, res: { modified: modified } }

  end

  def do_remote_puzzle_update

    status = 0
    message = "success"

    if params[:password] != ENV['REMOTE_ACCESS_PASSWORD']
      status = 1
      message = "unauthorised"
    end

    pack = Pack.find_by_pack_code params[:pack_id]
    
    if pack.nil?
      status = 1
      message = "No pack with that ID"
      modified = nil
    end

    puzzle_index = params[:puzzle_index].to_i
    single_puzzle = pack.pack_puzzles.where('position = ?', puzzle_index).first
    
    if !single_puzzle
      status = 1
      message = "No puzzle at that position"
      modified = nil
    end
    
    if status == 0

      single_puzzle.puzzle = params[:puzzle_data]
      single_puzzle.sanitize_imported_data
      single_puzzle.extract_data_from_json
      res = single_puzzle.save

      pack.modified_at = Time.now
      pack.published = false
      pack.save
      
      pack.match_assets
      modified = pack.modified_at.to_time.to_i

      @pack = pack

    end
    
    render json: {status: status, message: message, res: { modified: modified } }

  end

  def puzzle_redirect_path puzzle

    if params[:edit]
      r = edit_admin_puzzle_path(id: puzzle.id)
    else
      pack_id = @site_version == :jigsaw ? puzzle.jigsaw_pack.id : puzzle.pack.id
      r = edit_admin_pack_path(id: pack_id)
    end

  end

  def add_title_breadcrumb
    add_breadcrumb 'Puzzle Packs', admin_packs_path
  end


  # order is important here!
  # puzzle is set first, and then json elements overwritten. image is set first, then image_id is overwritten

  def puzzle_params
    l = Language.all.collect(&:code)
    params.require(:pack_puzzle).permit :puzzle, :extra_data, :image, :asset_image_id, :pack_id, answers: l, blacklist: l, caption: l
    
  end

  def puzzle_params_no_language
    params.require(:pack_puzzle).permit :puzzle, :extra_data, :image, :asset_image_id, :pack_id
  end

end

