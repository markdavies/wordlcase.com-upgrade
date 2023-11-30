class PackPuzzle < ActiveRecord::Base

  include Positionable

  positionable_scope :pack_id

  belongs_to :pack, touch: true
  belongs_to :puzzle_asset

  validates_presence_of :pack_id
  validates_presence_of :image_id
  validates_uniqueness_of :image_id, scope: :pack_id

  scope :not_placeholder, -> { where('placeholder = ?', false) }

  scope :for_date, lambda { |date|
    
    date_str = Pack.daily_code_for_date(date)
    joins(:pack).where('pack_code = :date_str and pack_puzzles.position = :position', {date_str: date_str, position: date.day - 1})

  }

  scope :search, lambda { |query| 

    builder = all

    builder = builder.joins(:pack)
    builder = builder.where("LOWER(puzzle) LIKE '%#{query.downcase}%' OR LOWER(packs.pack_code) LIKE '%#{query.downcase}%'") if query != ''
    builder = builder.group(:id)
    builder = builder.reorder('game_position asc')

    builder

  }

  before_save :downcase_image_id
  after_save :set_published_puzzle
  after_save :update_pack_modified_at
  after_save :update_pack_status

  MIN_ANSWER_LENGTH = 2
  MAX_ANSWER_LENGTH = 18

  # allow getting and setting of dynamic language values
  def method_missing(method_name, *args, &block)
    
    setter = method_name[-1] == '='
    args = args[0] if setter

    parsed_method = method_name.to_s.gsub '=', ''

    allowed_language_call(parsed_method) || super

    return nil if args.kind_of?(String)

    p = parsed_puzzle_data

    if setter

      if args.kind_of?(Array)
        a = {}
        a[args[0]] = args[1]
        args = a
      end

      args.each do |lang, value|

        lang = lang.to_s
        current_value = p[lang][parsed_method] rescue nil

        if parsed_method != 'caption'
          value = value.split(',').collect(&:strip)
          p[lang] = {} if p[lang].nil?
        end

        if value.length == 0
          p[lang].delete(parsed_method) if !p[lang].nil? && p[lang][parsed_method]
        else
          p[lang][parsed_method] = value
        end

        p.delete(lang) if !p[lang].nil? && p[lang].empty?

        new_value = p[lang][parsed_method] rescue nil

        # changing answers or blacklist should delete any layout value for this language
        # and set the pack to unpublished
        if p[lang] && parsed_method != 'caption' && new_value != current_value
          p[lang].delete('layout')
          self.pack.published = false
          self.pack.published_at = nil
        end

      end

      self.puzzle = p.to_json

    else

      language = args[0]

      return nil if p[language].nil?
      return p[language][parsed_method]

    end

  end

  def respond_to?(method_name, *)
    allowed_language_call(method_name) || super
  end

  def allowed_language_call method_name
    ['answers', 'blacklist', 'caption', 'quality', 'difficulty'].include? method_name
  end

  def downcase_image_id
    self.image_id = self.image_id.downcase
  end

  def quality language_code

    data = parsed_puzzle_data

    return false if !data.has_key?(language_code) || data[language_code].nil?

    return false if !data[language_code].has_key?('layout')
    layout = data[language_code]['layout']

    return false if !data[language_code]['layout'].has_key?('quality')
    quality = data[language_code]['layout']['quality']

    return quality
    
  end

  def image= value

    if puzzle_asset
      asset = puzzle_asset
    else
      asset = PuzzleAsset.new
      asset.pack_id = pack_id
      self.puzzle_asset = asset
    end

    if !self.image_id
      self.image_id = "puzzle_#{rand(36**10).to_s(36)}"
    end
    
    asset.image = value
    asset.image_id = image_id
    asset.save

  end

  def asset_image_id

    return puzzle_asset.image_id if puzzle_asset
    return image_id

  end

  def asset_image_id= value

    return if !value || value ==''

    self.image_id = value
    
    p = parsed_puzzle_data
    p['image'] = value
    self.puzzle = p.to_json

    puzzle_asset.update_attribute(:image_id, value) if puzzle_asset

  end

  def puzzle_or_fail show_published = true

    if show_published && puzzle_published.blank?
      return {status: 1, message: 'fail'}.to_json

    else
      data = feed_puzzle_data show_published
      return {status: 0, message: 'success', res: data}.to_json
      
    end

  end

  def set_published_puzzle

    if pack && pack.published
      self.update_column(:puzzle_published, self.puzzle)
    end

  end

  def feed_puzzle_data show_published = true

    data = parsed_puzzle_data(show_published)

    if pack.is_daily || pack.is_special
      data['required_app_version'] = pack.required_app_version
      if show_published
        data['modified'] = pack.published_at.to_time.to_i
      else
        data['modified'] = pack.modified_at.to_time.to_i
      end
    end
    
    if puzzle_asset

      path = File.dirname(puzzle_asset.image.url(:small, timestamp: false))
      path << '/' unless path.end_with?('/')
      data['images_url'] = path

    end

    data

  end

  def status
    
    data = parsed_puzzle_data
    
    languages = pack.is_chinese ? Language.chinese : Language.not_chinese
    languages = languages.collect(&:code)

    primary_lang = pack.is_chinese ? Language::CODE_CHINESE : Language::CODE_ENGLISH

    statuses = []
    
    if (languages - data.keys).length > 0
      statuses << Pack::STATUS_MISSING_LOCALES
    end

    languages.each do |language_code|
      is_primary = language_code == primary_lang

      if data[language_code].nil? || !data[language_code].has_key?('layout')
        statuses << Pack::STATUS_MISSING_LAYOUTS
        statuses << Pack::STATUS_MISSING_PRIMARY_LAYOUTS if is_primary
      end

      if !data[language_code].nil? && data[language_code].has_key?('answers')

        answers = data[language_code]['answers']
        blacklist = data[language_code].has_key?('blacklist') ? data[language_code]['blacklist'] : []
        
        answers.each do |answer|

          if answer.length > PackPuzzle::MAX_ANSWER_LENGTH || answer.length < PackPuzzle::MIN_ANSWER_LENGTH
            statuses << Pack::STATUS_INVALID_ANSWERS
            statuses << Pack::STATUS_INVALID_PRIMARY_ANSWERS if is_primary
          end

          if blacklist.include? answer
            statuses << Pack::STATUS_INVALID_ANSWERS
            statuses << Pack::STATUS_INVALID_PRIMARY_ANSWERS if is_primary
          end

        end

        if answers.uniq.length != answers.length
          statuses << Pack::STATUS_INVALID_ANSWERS
          statuses << Pack::STATUS_INVALID_PRIMARY_ANSWERS if is_primary
        end

      end

    end

    if puzzle_asset.nil?
      statuses << Pack::STATUS_MISSING_IMAGES
    end

    statuses << Pack::STATUS_PUBLISHED if statuses.length == 0

    statuses

  end

  def extract_data_from_json
    
    self.image_id = find_json_value_by_key('image')

  end

  def has_layouts

    data = parsed_puzzle_data
    languages = Language::all.collect(&:code)

    languages.each do |language_code|
      if !data[language_code].nil? && data[language_code].has_key?('layout')
        return true
      end
    end

    return false

  end

  def update_pack_modified_at
    pack.update_modified_at_time
  end

  def update_pack_status
    pack.update_status_column
  end

  def sanitize_imported_data
    
    data = parsed_puzzle_data
    languages = Language::all.collect(&:code)

    languages.each do |language_code|
      if !data[language_code].nil? && data[language_code].has_key?('answers')
        data[language_code]['answers'] = data[language_code]['answers'].join(',').gsub(' ', '').split(',')
      end
    end

    self.puzzle = data.to_json

  end

  def display_answers
    language_code = pack.is_chinese ? Language::CODE_CHINESE : Language::CODE_ENGLISH
    answers(language_code) || []
  end

  def game_position_or_date date_format = '%d %b'

    if pack.is_daily || pack.is_special
      date = Date.new(pack.year, pack.month, 1)

      date = date + position.days
      if pack.month == 2 && date.month == 3 
        year = pack.year
        year += 1 until Date.leap?(year)
        date = Date.new(year, pack.month, 29)
      end

      return date.strftime(date_format)
    else
      return game_position
    end

  end

  # private

  def parsed_puzzle_data show_published = false
    p = show_published ? puzzle_published : puzzle
    parsed = JSON.parse(p) rescue {}
    parsed = parsed['res'].nil? ? parsed : parsed['res']
  end

  def upload_bucket_domain

    if ENV['S3_HOST_ALIAS']
      'http://' + ENV['S3_HOST_ALIAS']
    else
      'http://s3.amazonaws.com/' + ENV['UPLOAD_BUCKET_NAME']
    end

  end

  def find_json_value_by_key key

    value = parsed_puzzle_data['res'][key] rescue ''
    if value == ''
      value = parsed_puzzle_data[key] rescue ''
    end

    value

  end
  
end


