module AdminHelper
  require 'fog'

  def pretty_date date, format=:full_date

    return '' if !date

    if date
      case format
      when :date
        return date.strftime("%-d %b %Y")
      when :full_date
        return date.strftime("%a %-d %b %Y")
      when :full_date_time
        return date.strftime("%H:%M %a %-d %b %Y")
      when :month_year
        return date.strftime("%b %Y")
      end
    end

  end

  def pretty_quality quality

    return '' if !quality

    config = AppConfig.get

    if quality >= config.quality_threshold_2
      level = 'danger'

    elsif quality >= config.quality_threshold_1
      level = 'warning'

    else
      level = 'default'

    end

    return "<span class='label label-#{level}'>#{quality}</span>"

  end

  def start_index
    page = params[:page] || 1
    per_page = params[:limit] || Kaminari.config.default_per_page
    per_page = per_page.to_i
    (page.to_i - 1) * per_page
  end

  def backup_assets

    return false if !ENV['AWS_DIRECTORY'] || !ENV['AWS_ACCESS_KEY_ID'] || !ENV['AWS_SECRET_ACCESS_KEY'] || !ENV['GCS_DIRECTORY'] || !ENV['GOOGLE_ACCESS_KEY_ID'] || !ENV['GOOGLE_SECRET_ACCESS_KEY']

    google = Fog::Storage.new({
      :provider                         => 'Google',
      :google_storage_access_key_id     => ENV['GOOGLE_ACCESS_KEY_ID'],
      :google_storage_secret_access_key => ENV['GOOGLE_SECRET_ACCESS_KEY'],
      :path_style            => true
    })

    google_bucket = google.directories.get ENV['GCS_DIRECTORY'], prefix: Rails.env
    return false if google_bucket == nil

    dest_objects = google_bucket.files.inject([]) do |ar, obj|
      ar << [obj.key, obj.content_length] if obj.content_length > 0
      ar
    end

    s3 = Fog::Storage.new({
      :provider              => 'AWS',
      :aws_access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
      :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    })

    s3_bucket = s3.directories.get ENV['AWS_DIRECTORY'], prefix: Rails.env
    return false if s3_bucket == nil

    src_objects = s3_bucket.files.inject([]) do |ar, obj|
      ar << [obj.key, obj.content_length] if obj.content_length > 0
      ar
    end

    puts src_objects.inspect

    puts "uploading new files"
    (src_objects - dest_objects).each do |obj|

      puts "uploading #{obj[0]}"

      file = google_bucket.files.create(
        :key            => obj[0],
        :body           => s3_bucket.files.get(obj[0]).body,
        :acl            => 'public-read',
        :content_type   => MIME::Types.type_for(obj[0]).first.content_type
      )

    end

    puts "deleting old files"
    (dest_objects - src_objects).each do |obj|
      puts "deleting #{obj[0]}"
      google.delete_object(ENV['GCS_DIRECTORY'], obj[0])
    end

  end

  def self.generate_puzzle_query_stats

    PuzzleQuery.all.each do |pq|
      pq.generate_stat
    end

  end

  def self.select_value_to_readable key, select_integer_to_val

    case key
      when :moderated
        case select_integer_to_val
          when 0
            return 'Unmoderated'
          when 1
            return 'Moderated'
        end
      when :inappropriate
        case select_integer_to_val
          when -2
            return 'Appropriate (Reported)'
          when -1
            return 'Appropriate (Locked)'
          when 0
            return 'Appropriate'
          when 1
            return 'Inappropriate'
        end
      when :is_large
        case select_integer_to_val
          when true
            return 'Yes'
          when false
            return 'No'
        end
    end

  end

  def region_title region_code

    return '' if region_code.nil?

    key   = region_code.upcase
    names = Rails.application.config.jigsaw_puzzle_regions

    return names.has_key?(key) ? names[key] : ''

  end

  def ugc_puzzle_classes puzzle

    classes = []
    classes.push 'puzzle-disabled' if !puzzle.status
    classes.push 'puzzle-private' if puzzle.privacy.nil? || puzzle.privacy == 'private'
    classes.push 'report-alert' if puzzle.inappropriate == 1
    classes.push 'appropriate-report-alert' if puzzle.inappropriate == -2

    classes.join ' '

  end

  def appropriateness_select_values add_all = true, add_any_appropriate = false

    select_values = [['Appropriate (Reported)', '-2'], ['Appropriate (Locked)', '-1'], ['Appropriate', '0']]

    if add_all
      select_values.unshift ['All', '10']
    end

    if add_any_appropriate
      select_values.push ['Any Appropriate', '-10']
    end

    select_values.push ['Inappropriate', '1']

    return select_values

  end

  def appropriateness_value value

    appropriateness_select_values(true, true).each do |item|
      return item[0] if value.to_s == item[1]
    end

    return 'All'

  end

  def alphabetised_regions add_none = true
    regions = Rails.application.config.jigsaw_puzzle_regions
    regions = regions.sort_by {|_key, value| value}.to_h
    regions = {'' => 'None'}.merge(regions) if add_none
    regions
  end

  def status_human status
    
    case status

    when Pack::STATUS_PROCESSING
      "Processing"

    when Pack::STATUS_PUBLISHED
      "Published"

    when Pack::STATUS_TESTING
      "Testing"

    when Pack::STATUS_EMPTY
      "Empty"

    when Pack::STATUS_MISSING_PRIMARY_LAYOUTS
      "Missing Primary Layouts"

    when Pack::STATUS_INVALID_PRIMARY_ANSWERS
      "Invalid Primary Answers"

    when Pack::STATUS_TESTING_PRIMARY
      "Testing Primary"

    when Pack::STATUS_MISSING_LAYOUTS
      "Missing Layouts"

    when Pack::STATUS_INVALID_ANSWERS
      "Invalid Answers"

    when Pack::STATUS_MISSING_LOCALES
      "Missing Locales"

    when Pack::STATUS_MISSING_IMAGES
      "Missing Images"

    when Pack::STATUS_MISSING_PUZZLES
      "Missing Puzzles"

    when Pack::STATUS_TOO_MANY_PUZZLES
      "Too Many Puzzles"

    when Pack::STATUS_UNUSED_IMAGES
      "Unused Images"

    end

  end

  def status_class status

    if status == Pack::STATUS_TESTING || status == Pack::STATUS_TESTING_PRIMARY
      status_class = 'warning' 
    elsif status == Pack::STATUS_MISSING_LOCALES
      status_class = 'custom-pink' 
    elsif status == Pack::STATUS_MISSING_LAYOUTS || status == Pack::STATUS_MISSING_PRIMARY_LAYOUTS
      status_class = 'primary' 
    elsif status == Pack::STATUS_PUBLISHED
      status_class = 'default' 
    else
      status_class = 'danger' 
    end

    status_class

  end

  def next_pack_url pack
    adjacent_pack_url pack, 'next'
  end

  def prev_pack_url pack
    adjacent_pack_url pack, 'prev'
  end

  def adjacent_pack_url pack, direction
    adjacent = PackOps.get_adjacent_pack pack, direction
    return false if !adjacent
    return edit_admin_pack_path(id: adjacent)
  end

end



