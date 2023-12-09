class Pack < ActiveRecord::Base

  require 'zip'

  include Positioner
  include AdminHelper

  has_many :pack_puzzles, dependent: :destroy, after_remove: :update_modified_at_time, after_add: :update_modified_at_time
  has_many :puzzle_assets, dependent: :destroy, after_remove: :update_modified_at_time, after_add: :update_modified_at_time

  positions :pack_puzzles

  after_save :set_published_puzzles
  after_create :update_modified_at_time
  before_save :get_status
  
  has_one_attached :pack_parcel
  has_one_attached :draft_pack_parcel

  validates_uniqueness_of :pack_code
  validates_presence_of :pack_code

  default_scope { reorder('pack_code asc') }

  scope :oldest, -> { reorder('pack_code desc') }

  scope :filtered, lambda { |filters|

    filters = [filters] if !filters.kind_of?(Array)

    builder = all

    filters.reject! do |filter|
      ![Pack::TYPE_DAILY, Pack::TYPE_CLASSIC, Pack::TYPE_CHINESE, Pack::TYPE_SPECIAL].include?(filter)
    end

    if filters.length > 0
      
      where = filters.collect do |filter|
        "pack_code LIKE '#{filter}%'"
      end

      builder = builder.where(where.join(' or '))
      
    end

    builder

  }

  scope :invalid, -> { where('status != ?', Pack::STATUS_PUBLISHED) }

  attr_accessor :flash_alert

  TYPE_DAILY = 'daily'
  TYPE_CLASSIC = 'classic'
  TYPE_CHINESE = 'chinese'
  TYPE_SPECIAL = 'special'
  
  STATUS_PROCESSING = 'processing'
  STATUS_PUBLISHED = 'published'
  STATUS_TESTING = 'testing'
  STATUS_EMPTY = 'empty'
  STATUS_MISSING_PRIMARY_LAYOUTS = 'missing-primary-layouts'
  STATUS_INVALID_PRIMARY_ANSWERS = 'invalid-primary-answers'
  STATUS_TESTING_PRIMARY = 'testing-primary'
  STATUS_MISSING_LAYOUTS = 'missing-layouts'
  STATUS_INVALID_ANSWERS = 'invalid-answers'
  STATUS_MISSING_LOCALES = 'missing-locales'
  STATUS_MISSING_IMAGES = 'missing-images'
  STATUS_MISSING_PUZZLES = 'missing-puzzles'
  STATUS_TOO_MANY_PUZZLES = 'too-many-puzzles'
  STATUS_UNUSED_IMAGES = 'unused-images'

  GOOGLE_SHEET_PACKS_PER_DOC = 100
  DAILY_PUZZLES_PER_PACK = 10

  def is_daily
    is_type Pack::TYPE_DAILY
  end

  def is_special
    is_type Pack::TYPE_SPECIAL
  end

  def is_chinese
    is_type Pack::TYPE_CHINESE
  end

  def is_classic
    is_type Pack::TYPE_CLASSIC
  end

  def is_type type
    return false if !pack_code
    pack_code[0..type.length-1] == type
  end

  def pack_type
    return '' if !pack_code

    if is_daily
      return Pack::TYPE_DAILY
    elsif is_chinese
      return Pack::TYPE_CHINESE
    elsif is_classic
      return Pack::TYPE_CLASSIC
    elsif is_special
      return Pack::TYPE_SPECIAL
    end

  end

  def google_sheet_file_name
    file = "WL Puzzles #{import_file_name}"
  end

  def drop_box_folder_location
    file = "#{ENV['DROPBOX_FOLDER_PREFIX']}/#{import_file_name}/#{pack_code}/"
  end

  def import_file_name

    file = "#{pack_type.capitalize} "
    parts = pack_code.split('_')

    return false if parts.length < 2

    if is_daily || is_special

      file << year.to_s

    else

      idx_start = ((indexes[0].to_i / Pack::GOOGLE_SHEET_PACKS_PER_DOC) * Pack::GOOGLE_SHEET_PACKS_PER_DOC) + 1
      idx_end = idx_start + Pack::GOOGLE_SHEET_PACKS_PER_DOC - 1

      file << "#{sprintf('%04d', idx_start)}-#{sprintf('%04d', idx_end)}"

    end

    file

  end

  def month
    return nil if !is_daily && !is_special
    month_and_year[0]
  end

  def year
    return nil if !is_daily && !is_special
    month_and_year[1]
  end

  def month_and_year
    return nil if !is_daily && !is_special

    parts = pack_code.split('_')
    [parts.third.to_i, parts.second.to_i]

  end

  def start_date
    return nil if !is_daily && !is_special

    month, year = month_and_year

    begin
      date = Date.new(year, month, 1)
    rescue ArgumentError
      nil
    end

  end

  def self.daily_code_for_date date
    "#{Pack::TYPE_DAILY}_#{date.year}_#{sprintf('%02d', date.month)}_#{date.strftime('%b').downcase}"
  end

  def indexes
    return nil if is_daily || is_special

    parts = pack_code.split('_')
    parts.second.split('-')

  end

  def update_status_column
    self.update_column(:status, get_status)
  end

  def get_status

    self.pack_puzzles.reload

    st = nil

    if data_processing || images_processing
      st = Pack::STATUS_PROCESSING
    elsif pack_puzzles.length == 0
      st = Pack::STATUS_EMPTY
    elsif !is_daily && !is_special && pack_puzzles.length < 10
      st = Pack::STATUS_MISSING_PUZZLES
    elsif !is_daily && !is_special && pack_puzzles.length > 10
      st = Pack::STATUS_TOO_MANY_PUZZLES
    elsif is_special && pack_puzzles.length < 6
      st = Pack::STATUS_MISSING_PUZZLES
    elsif is_special && pack_puzzles.length > 6
      st = Pack::STATUS_TOO_MANY_PUZZLES
    elsif is_daily
      date = start_date
      
      end_of_month = date.end_of_month.day
      end_of_month = 29 if date.month == 2

      if !date or end_of_month > pack_puzzles.length
        st = Pack::STATUS_MISSING_PUZZLES
      elsif end_of_month < pack_puzzles.length
        st = Pack::STATUS_TOO_MANY_PUZZLES
      end
    end

    if st.nil?

      invalid_primary_answers = false
      missing_primary_layout = false
      invalid_answers = false
      missing_layout = false
      missing_locale = false
      missing_images = false

      pack_puzzles.each do |puzzle|

        statuses = puzzle.status

        missing_locale = true if statuses.include?(Pack::STATUS_MISSING_LOCALES)
        missing_layout = true if statuses.include?(Pack::STATUS_MISSING_LAYOUTS)
        missing_primary_layout = true if statuses.include?(Pack::STATUS_MISSING_PRIMARY_LAYOUTS)
        invalid_answers = true if statuses.include?(Pack::STATUS_INVALID_ANSWERS)
        invalid_primary_answers = true if statuses.include?(Pack::STATUS_INVALID_PRIMARY_ANSWERS)
        missing_images = true if statuses.include?(Pack::STATUS_MISSING_IMAGES)

        puzzle.update_column(:status_missing_locales, statuses.include?(Pack::STATUS_MISSING_LOCALES))
        puzzle.update_column(:status_invalid, statuses.include?(Pack::STATUS_INVALID_ANSWERS) || statuses.include?(Pack::STATUS_INVALID_PRIMARY_ANSWERS))

      end

      if missing_images
        st = Pack::STATUS_MISSING_IMAGES
      elsif orphaned_assets.length > 0
        st = Pack::STATUS_UNUSED_IMAGES
      elsif invalid_primary_answers
        st = Pack::STATUS_INVALID_PRIMARY_ANSWERS
      elsif invalid_answers
        st = Pack::STATUS_INVALID_ANSWERS
      elsif missing_primary_layout
        st = Pack::STATUS_MISSING_PRIMARY_LAYOUTS
      elsif !tested_primary
        st = Pack::STATUS_TESTING_PRIMARY
      elsif missing_locale
        st = Pack::STATUS_MISSING_LOCALES
      elsif missing_layout
        st = Pack::STATUS_MISSING_LAYOUTS
      elsif !published
        st = Pack::STATUS_TESTING
      else
        return Pack::STATUS_PUBLISHED
      end

    end

    self.status = st

  end

  def status_constant
    status.gsub('-','_').upcase
  end

  def is_publishable
    [Pack::STATUS_TESTING, Pack::STATUS_PUBLISHED].include?(status)
  end

  def orphaned_assets

    used = pack_puzzles.collect(&:puzzle_asset_id).reject{|id| id.nil? }
    
    if !used.nil? && used.length > 0
      puzzle_assets.where("id NOT IN (?)", used)
    else
      puzzle_assets
    end

  end

  def match_assets

    pack_puzzles.each do |puzzle|

      asset = puzzle_assets.where('image_id = ?', puzzle.image_id).first

      if asset
        puzzle.puzzle_asset = asset
        puzzle.save
      end

    end

  end

  def assets
    self.pack_puzzles.collect(&:puzzle_asset)
  end

  # def style_file_name attachment, style
  #   return "parcels/#{attachment.name == :pack_parcel ? '' : 'draft_'}#{self.pack_code}"
  # end

  def set_published_puzzles

    if published_changed? && published == true

      pack_puzzles.each do |puzzle|

        puzzle.update_column(:puzzle_published, puzzle.puzzle)

      end
      
      self.update_column(:published_at, Time.now)

    end

  end

  def existing_or_new_puzzle_by_position position

    return pack_puzzles[position] if !pack_puzzles[position].nil?

    p = pack_puzzles.new
    p.position = position
    return p

  end

  def has_layouts

    pack_puzzles.each do |pp|
      return true if pp.has_layouts
    end

    return false

  end

  def quality language_code

    worst = false

    pack_puzzles.each do |pp|
      quality = pp.quality(language_code)
      if quality != false && (worst == false || quality > worst)
        worst = quality
      end
    end

    return worst

  end

  def delayed_parcel_process

      col = published ? 'parcel_processing' : 'draft_parcel_processing'
      self.update_column(col, true)

      PackOps.delay.refresh_zip self, published

  end

  def delayed_data_import content = nil, language = []

      self.update_column(:data_processing, true)
      self.update_column(:status, self.get_status)

      DataImporter.delay.import_for_pack self, content, language

  end

  def delayed_images_import

      self.update_column(:images_processing, true)
      self.update_column(:status, self.get_status)
      ImageImporter.delay.import_for_pack self

  end

  def update_modified_at_time pack_puzzle = nil
    self.update_column(:modified_at, Time.now)
  end

  def position
    
    packs = Pack.filtered(self.pack_type).select('packs.*, (select count(*) from pack_puzzles where pack_puzzles.pack_id = packs.id) as pack_puzzles_count')

    pack_index = packs.collect(&:id).index(self.id)
    return 0 if pack_index == 0
    packs = packs[0..pack_index-1]
    packs.inject(0) do |count, pack|
      count = count + pack.pack_puzzles_count
    end
  end

end
