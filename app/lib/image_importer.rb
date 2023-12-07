require "logger"

module ImageImporter

    def self.import_for_pack pack

        #begin

            client = self.start_session
            files = client.list_folder pack.drop_box_folder_location

            delete_before = pack.puzzle_assets.reorder('updated_at desc').first

            files.entries.each do |entry|

                image_id = File.basename(entry.name, File.extname(entry.name)).downcase
                
                client.download(entry.path_lower) do |image|

                    tmp_path = Rails.root.join('tmp', entry.name)

                    open(tmp_path, 'wb') do |tmp|
                        tmp.write image
                    end

                    image = open(tmp_path)

                    puzzle_asset = PuzzleAsset.find_or_create_by(pack_id: pack.id, image_id: image_id)
                    puzzle_asset.image.attach(io: image, filename: entry.name)
                    puzzle_asset.save!

                    puts puzzle_asset.inspect

                    image.close

                end

            end

            if delete_before
                pack.puzzle_assets.where('updated_at <= ?', delete_before.updated_at).destroy_all
            end


        # rescue DropboxApi::Errors::NotFoundError => e
        #     Rails.logger.error "#{pack.drop_box_folder_location} not found in DropBox"

        # rescue StandardError => e
        #     Rails.logger.error e.message

        # end

        pack.images_processing = false
        pack.published = false
        pack.save

        pack.match_assets
        
        PackOps.delay.refresh_pack_puzzle_game_positions
        PackOps.delay.refresh_zip pack
        PackOps.set_sprite_sheet_status('stale') if pack.pack_type != ''

    end

    private 

    def self.start_session
        return DropboxApi::Client.new
    end

end