class DataController < ActionController::Base
  include ApplicationHelper

  def dailypuzzle

    date, oob = get_date

    is_admin = params[:password] && params[:password] == ENV['REMOTE_ACCESS_PASSWORD']

    @daily_puzzle = PackPuzzle.for_date(date).first || PackPuzzle.new

    @published_only = !is_admin

    render :layout => false, content_type: "application/json"

    fresh_when @daily_puzzle, public: true
    expires_in 10.minutes, public: true

  end

  def pack_list
    
    request.format = :json

    get_pack_list

    respond_to do |format|
      format.json
    end

    fresh_when(etag: @packs, public: true)
    expires_in 10.minutes, public: true

  end

  def pack_list_chinese
    
    request.format = :json

    get_pack_list Pack::TYPE_CHINESE
    
    respond_to do |format|
      format.json
    end

    fresh_when(etag: @packs, public: true)
    expires_in 10.minutes, public: true


  end

  def pack_puzzle
    
    request.format = :json

    i = params[:index].to_i

    pack = Pack.find_by_pack_code(params[:id])

    if pack && pack.puzzles[i]
      puzzle = pack.puzzles[i]
      @output = puzzle.puzzle_or_fail
    else
      @output = nil
    end

    fresh_when puzzle, public: true
    expires_in 10.minutes, public: true

    respond_to do |format|
      format.json
    end

    fresh_when @puzzle, public: true
    expires_in 10.minutes, public: true

  end

  def get_server_date

    @date = Time.now.strftime('%Y-%m-%d %H:%M:%S')

    respond_to do |format|
      format.json{ render :layout => false }
    end

    expires_in 1.minutes, public: true

  end

  private

  def data_params
    l = I18n.available_locales
    params.permit :version, :date
  end

  def get_date

    date      = data_params[:date].to_datetime rescue Time.now
    is_admin  = params[:password] && params[:password] == ENV['REMOTE_ACCESS_PASSWORD']
    oob = false

    if !is_admin && (date < Time.now - 3.days || date > Time.now + 3.days)
      date = Time.now
      oob = true
    end

    [date, oob]

  end

  def get_pack_list type = false

    filters = type == 'chinese' ? [Pack::TYPE_CHINESE] : [Pack::TYPE_CLASSIC, Pack::TYPE_DAILY, Pack::TYPE_SPECIAL]

    @packs, @published_at, @modified_at = PackOps.pack_list(filters)

    @published_at = @published_at ? @published_at.to_time.to_i : nil
    @modified_at = @modified_at ? @modified_at.to_time.to_i : nil

  end

end

