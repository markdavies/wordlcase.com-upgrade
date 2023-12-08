module PackOps

  def self.pack_list filters = false, only_published = false

    pack_list = []
    packs = Pack.all
    packs = packs.where(published: true) if only_published
    packs = packs.includes(:pack_puzzles)
    packs = packs.filter(filters) if filters

    published_at = false
    modified_at = false

    packs.each do |pack|

      pack_meta = {
        total_puzzles: pack.pack_puzzles.length,
        pack_id: pack.pack_code,
        published: pack.published_at ? pack.published_at.to_time.to_i : nil,
        modified: pack.modified_at ? pack.modified_at.to_time.to_i : nil,
        status: pack.status_constant
      }

      pack_list << pack_meta

      published_at = pack.published_at if !published_at || (pack.published_at && pack.published_at > published_at)
      modified_at = pack.modified_at if !modified_at || (pack.modified_at && pack.modified_at > modified_at)

    end

    [pack_list, published_at, modified_at]

  end

  def self.add_images_to_zip_output_stream zos, pack_code, puzzle_assets, use_prefix = false

    service = Rails.application.config.active_storage.service
    keys = []

    puzzle_assets.reject(&:nil?).each do |puzzle_asset|

      if puzzle_asset.image.attached?
        ext = puzzle_asset.image.blob.filename.extension_with_delimiter
        prefix = ''
        prefix = use_prefix ? 'parcels/' : ''
        folder = 'images/'
        filename = puzzle_asset.image_id

        entry_key = "#{prefix}#{pack_code}/#{folder}#{filename}#{ext}"

        if !keys.include?(entry_key)

          zos.put_next_entry(entry_key)

          keys << entry_key
          processed = puzzle_asset.image.variant(resize_to_limit: [768, 768]).processed

          if service == :local
            zos.print processed.service.download(processed.key)
          else
            url = Rails.application.routes.url_helpers.rails_representation_url(processed.processed)
            zos.print URI.parse(url).read
          end

        end

      end
    
    end

  end

  def self.refresh_zip pack, published = false

    Delayed::Worker.logger.debug("refresh_zip for pack #{pack.pack_code} #{published ? 'published' : ''}")

    puzzles = {
      puzzles:  [],
      published: pack.published_at ? pack.published_at.to_time.to_i : nil,
      modified: pack.modified_at ? pack.modified_at.to_time.to_i : nil,
      pack_id: pack.pack_code
    }

    pack.pack_puzzles.each do |pack_puzzle|

      puzzle              = JSON.parse(pack_puzzle.puzzle) rescue nil
      puzzles[:puzzles]   << puzzle if !puzzle.nil?

    end

    tmp_zip = Rails.root.join('tmp') + "#{pack.pack_code}_#{Time.now.to_i}.zip"

    Zip::OutputStream.open(tmp_zip) do |zos|

      zos.put_next_entry("#{pack.pack_code}/#{pack.pack_code}.json")
      zos.puts puzzles.to_json

      a = pack.assets

      PackOps.add_images_to_zip_output_stream zos, pack.pack_code, a, false

    end

    filename = published ? "#{pack.pack_code}.zip" : "draft_#{pack.pack_code}.zip"

    if published
      pack.pack_parcel.attach(io: File.open(tmp_zip), filename: filename)
      pack.parcel_processing = false
    else
      pack.draft_pack_parcel.attach(io: File.open(tmp_zip), filename: filename)
      pack.draft_parcel_processing = false
    end

    pack.save

    File.delete(tmp_zip)

  end

  def self.bulk_create_packs type, number

    packs = Pack.filtered type
    pack_codes = []

    if type == Pack::TYPE_DAILY || type == Pack::TYPE_SPECIAL

      if packs.last
        start_date = packs.last.start_date
      else
        ref_date = type == Pack::TYPE_DAILY ? Date.today : Date.new(2021, 1, 1)
        ref_date = Date.today if ref_date < Date.today
        start_date = Date.new(ref_date.year, ref_date.month, 1) - 1.month
      end

      number.times do |i|
        pack_date = start_date + (i+1).months
        pack_codes << "#{type}_#{pack_date.year}_#{sprintf('%02d', pack_date.month)}_#{pack_date.strftime('%b').downcase}"
      end

    else

      if packs.last
        last_index = packs.last.indexes[1].to_i + 1
      else
        last_index = 1
      end

      number.times do |i|
        pack_start_index = last_index + (i * Pack::DAILY_PUZZLES_PER_PACK)
        pack_end_index = pack_start_index + Pack::DAILY_PUZZLES_PER_PACK - 1 
        pack_codes << "#{type}_#{sprintf('%04d', pack_start_index)}-#{sprintf('%04d', pack_end_index)}"
      end

    end

    pack_codes.each do |pack_code|
      p = Pack.new(pack_code: pack_code)
      p.save
    end

  end


  def self.get_adjacent_pack pack, direction

    packs = Pack.filtered pack.pack_type
    i = packs.find_index do |p|
      p.pack_code == pack.pack_code
    end

    i = i + (direction == 'next' ? 1 : -1)
    adjacent = packs[i % packs.length]
    return adjacent == pack ? false : adjacent

  end

  def self.refresh_pack_puzzle_game_positions

    [Pack::TYPE_DAILY, Pack::TYPE_CLASSIC, Pack::TYPE_CHINESE].each do |pack_type|
      
      data = PackPuzzle.connection.select_all("select pack_puzzles.id, pack_puzzles.position, pack_id, packs.pack_code, game_position from pack_puzzles inner join packs on packs.id = pack_puzzles.pack_id where packs.pack_code like '#{pack_type}%' order by packs.pack_code asc, pack_puzzles.position asc");
      id_data_index = data.columns.find_index('id')
      gp_data_index = data.columns.find_index('game_position')

      data.rows.each_with_index do |puzzle_row, i|
        old_position = puzzle_row[gp_data_index].to_i
        new_position = i + 1

        if old_position != new_position
          PackPuzzle.find(puzzle_row[id_data_index]).update_column(:game_position, new_position)
        end

      end

    end

  end

  def self.get_words_and_captions_for_lang lang_code, pack_type = nil

    if !pack_type.nil?
      packs = Pack.filtered(pack_type)
      puzzles = packs.collect(&:pack_puzzles).flatten
    else
      puzzles = PackPuzzle.all.reorder('game_position asc')
    end

    puzzles.collect do |pp|
      data = pp.parsed_puzzle_data
      answers = data[lang_code]['answers'] rescue []
      caption = data[lang_code]['caption'] rescue nil
      {game_position: pp.game_position_or_date('%d %b %Y'), answers: answers, caption: caption}
    end

  end

  def self.set_sprite_sheet_status status = 'stale'

    config = AppConfig.get
    config.sprite_sheet_status = status
    config.save

  end

  def self.generate_all_sprite_sheets

    PackOps.set_sprite_sheet_status 'refreshing'

    [Pack::TYPE_DAILY, Pack::TYPE_CLASSIC, Pack::TYPE_CHINESE, Pack::TYPE_SPECIAL].each do |pack_type|
      PackOps.generate_sprite_sheets pack_type
    end

    PackOps.set_sprite_sheet_status 'fresh'

  end

  def self.generate_sprite_sheets pack_type

    PuzzleAssetSheet.where('pack_type = ?', pack_type).destroy_all

    w = 2048
    h = 2048
    w_assets = 20
    h_assets = 20

    packs = Pack.filtered(pack_type)

    if pack_type == Pack::TYPE_DAILY

      thumb_groups = packs.inject({}) do |thumb_groups, pack|
        thumb_groups[pack.year] = [] if !thumb_groups[pack.year]
        
        images = pack.pack_puzzles.collect do |puzzle|
          begin
            puzzle.puzzle_asset.image(:thumb) ? puzzle.puzzle_asset : nil
          rescue 
            nil
          end
        end

        thumb_groups[pack.year].push images
        thumb_groups[pack.year].flatten!
        thumb_groups

      end

    else
      
      puzzles = packs.collect(&:pack_puzzles).flatten

      thumb_groups = puzzles.collect do |puzzle|
        begin
          puzzle.puzzle_asset.image(:thumb) ? puzzle.puzzle_asset : nil
        rescue 
          nil
        end
      end.compact.each_slice(PuzzleAssetSheet::IMAGES_PER_SPRITE_SHEET).to_a

    end

    thumb_groups.each_with_index do |thumb_group, idx|

      tmp_path = "tmp/thumbs_#{pack_type}_#{idx}.jpg"
      puzzle_assets = pack_type == Pack::TYPE_DAILY ? thumb_group[1] : thumb_group

      MiniMagick::Tool::Convert.new do |convert|

        convert << "-size"
        convert << "2048x2048"
        convert << "canvas:white"
        convert << tmp_path

      end

      puzzle_assets.each_with_index do |puzzle_asset, idx_asset|

        destination = MiniMagick::Image.open(tmp_path)

        image = puzzle_asset.image
        url = ENV['FOG_DIRECTORY'] ? image.url(:thumbnail) : image.path(:thumbnail)
        puts url
        a = MiniMagick::Image.open(url)
        x = (idx_asset % w_assets) * 100
        y = ((idx_asset / w_assets.to_f).floor) * 100

        result = destination.composite(a) do |c|
          c.compose "Over"
          c.geometry "+#{x}+#{y}"
        end

        result.write tmp_path

      end
      
      sheet = PuzzleAssetSheet.new
      sheet.position = idx
      sheet.year = thumb_group[0] if pack_type == Pack::TYPE_DAILY
      sheet.pack_type = pack_type
      sheet.image = File.open(tmp_path)
      sheet.save

    end

    PackOps.generate_sprite_sheets_zip

  end

  def self.generate_sprite_sheets_zip

    sheets  = PuzzleAssetSheet.all
    tmp_zip = Rails.root.join('tmp') + "puzzle_sheets_#{Time.now.to_i}.zip"

    Zip::OutputStream.open(tmp_zip) do |zos|

      sheets.each do |sheet|

        entry_key = File.basename(sheet.image.url)
        entry_key = entry_key.split('?')[0]

        zos.put_next_entry(entry_key)

        if sheet.image.options[:storage] == :filesystem
          zos.print File.read(sheet.image.path(:original))
        else
          zos.print URI.parse(sheet.image(:original)).read
        end

      end

    end

    config = AppConfig.get
    config.puzzle_sheets = File.open(tmp_zip)
    config.save

  end

end

