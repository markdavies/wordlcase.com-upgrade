module SocialHelper

  def auto_post date

    if date.nil?
      ref_date = DateTime.now.in_time_zone('Australia/Sydney')
      new_year = (2020 + (ref_date.year - 1) % 3)
      ref_date = Date.parse("#{new_year}-#{ref_date.month}-#{ref_date.day}")
    else
      ref_date = Date.parse(date)
    end

    file = Rails.root.join('app', 'assets', 'images', 'social-wordlaces-overlay.png')

    puzzle = PackPuzzle.for_date(ref_date).first
    return false if !puzzle || !puzzle.puzzle_asset

    asset = puzzle.puzzle_asset
    return false if !asset.image

    caption = puzzle.caption(Language::CODE_ENGLISH)
    return false if caption.nil?

    if asset.image.options[:storage] == :filesystem
      image_url = asset.image.path(:medium_lg)
    else
      image_url = asset.image(:medium_lg)
    end

    underlay = MiniMagick::Image.open(image_url)
    overlay = MiniMagick::Image.new(file)

    scale = underlay.width.to_f / overlay.width.to_f

    new_width = (overlay.width * scale).to_i
    new_height = (overlay.height * scale).to_i
    offset_y = ((underlay.height - new_height) / 2).to_i

    result = underlay.composite(overlay) do |c|
      c.compose 'Over'
      c.geometry "#{new_width}x#{new_height}+0+#{offset_y}"
    end
    
    result.crop "#{new_width}x#{new_height}+0+#{offset_y}"
    result.resize("#{overlay.width}x#{overlay.height}")

    tmp_path = 'tmp/social-wordlaces-daily.jpg'
    result.write tmp_path

    caption = "#{caption} Check out today's daily puzzle for Word Laces."

    # twitter
    message = "#{caption} #applearcade #{ENV['SOCIAL_SHORT_LINK']}"
    post_to_twitter message, tmp_path

    # facebook
    post_to_facebook "#{caption} #{(rand < 0.5) ? ENV['SOCIAL_SHORT_LINK'] : ' #applearcade' }", tmp_path

  end

  def post_to_twitter message, filepath

    app_config = AppConfig.get

    twitter = Twitter::REST::Client.new do |config|
      config.consumer_key = ENV['TWITTER_API_KEY']
      config.consumer_secret = ENV['TWITTER_API_SECRET']
      config.access_token = app_config.twitter_access_token
      config.access_token_secret = app_config.twitter_access_token_secret
    end

    twitter.update_with_media(message, File.new(filepath))

  end

  def post_to_facebook message, filepath

    graph = Koala::Facebook::API.new(ENV['FACEBOOK_API_PERMANENT_TOKEN'])
    picture = Koala::HTTPService::UploadableIO.new(File.open(filepath), 'image')

    post =  graph.put_object(
              ENV['FACEBOOK_PAGE_ID'], 
              'photos', 
              message: message, 
              source: picture)

  end

end

