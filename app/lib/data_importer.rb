require "google_drive"
require "logger"

module DataImporter

    def self.import_for_pack pack, content = 'all', language = nil

        captions = content == 'captions'

        # begin

            all_languages = Language::all.collect(&:code)
            all_languages = pack.is_chinese ? Language::all.chinese : Language::all.not_chinese
            all_languages = all_languages.collect(&:code).to_a

            language = all_languages if language.nil?

            safe_languages = all_languages.select do |lang|
                !language.include?(lang)
            end

            puts "Importing #{content} #{pack.pack_code} for #{language.join(',')}"

            safe_lang_json = pack.pack_puzzles.inject({}) do |h, pp| 
                
                safe_languages.each do |lang|
                    h[pp.image_id] = {} if !h.has_key?(pp.image_id)
                    h[pp.image_id][lang] = 'ads'
                    h[pp.image_id][lang] = pp.find_json_value_by_key(lang)
                end

                h
                
            end

            safe_published_puzzles = pack.pack_puzzles.inject({}) do |h, pp| 

                h[pp.image_id] = pp.puzzle_published
                h
                
            end

            worksheet = DataImporter::get_worksheet pack
            data, keys = DataImporter::parse_worksheet worksheet

            if captions

                data.each do |puzzle_data|

                    puzzle = pack.pack_puzzles.find do |pp|
                        pp.image_id == puzzle_data[:image].downcase
                    end

                    if puzzle
                        p = puzzle.parsed_puzzle_data

                        language.each do |language_code|

                            if !p[language_code].nil? && !puzzle_data[language_code]['caption'].nil?
                                p[language_code]['caption'] = puzzle_data[language_code]['caption']
                            elsif !p[language_code].nil? && puzzle_data[language_code]['caption'].nil?
                                p[language_code].delete('caption')
                            end

                        end

                        puzzle.puzzle = p.to_json
                        puzzle.save

                    end
                    
                end

            else

                pack.pack_puzzles.clear

                data.each do |puzzle_data|

                    puzzle = pack.pack_puzzles.new
                    puzzle.image_id = puzzle_data[:image].downcase

                    if !safe_lang_json[puzzle.image_id].nil?

                        safe_lang_json[puzzle.image_id].each do |lang, data|
                            puzzle_data[lang] = data
                        end

                    end

                    if !safe_published_puzzles[puzzle.image_id].nil?
                        puzzle.puzzle_published = safe_published_puzzles[puzzle.image_id]
                    end

                    puzzle.puzzle = puzzle_data.to_json
                    puzzle.sanitize_imported_data
                    pack.pack_puzzles << puzzle

                end

            end

            pack.worksheet_url = worksheet.human_url

        # rescue DataImporterError => e
        #     Rails.logger.error e.message

        # rescue StandardError => e
        #     Rails.logger.error e.message
        # end

        pack.published = false
        pack.data_processing = false
        pack.save

        pack.match_assets

        pack.update_status_column
        
        PackOps.delay.refresh_pack_puzzle_game_positions
        PackOps.delay.refresh_zip pack
        PackOps.set_sprite_sheet_status('stale') if pack.pack_type != ''

    end

    def self.import_for_puzzle puzzle, content = 'all', language = nil

        captions = content == 'captions'

        pack = puzzle.pack

        all_languages = pack.is_chinese ? Language::all.chinese : Language::all.not_chinese
        language = all_languages.collect(&:code) if language.nil?

        safe_languages = all_languages.collect(&:code).to_a.select do |lang|
            !language.include?(lang)
        end

        begin

            worksheet = DataImporter::get_worksheet pack
            return false if !worksheet

            data, keys = DataImporter::parse_worksheet worksheet

            puzzle_index = keys.index(puzzle.image_id)
            
            raise DataImporterError.new('Cannot find puzzle data') if puzzle_index.nil?

            puzzle_data = data[puzzle_index]

            safe_languages.each do |lang, data|
                value = puzzle.find_json_value_by_key(lang)
                puzzle_data[lang] = value if !value.nil?
            end

            if captions

                puzzle = pack.pack_puzzles.find do |pp|
                    pp.image_id == puzzle_data[:image].downcase
                end

                p = puzzle.parsed_puzzle_data

                languages.each do |language_code|
                    if !p[language_code].nil? && !puzzle_data[language_code]['caption'].nil?
                        p[language_code]['caption'] = puzzle_data[language_code]['caption']
                    elsif !p[language_code].nil? && puzzle_data[language_code]['caption'].nil?
                        p[language_code].delete('caption')
                    end
                end

                puzzle.puzzle = p.to_json

            else

                puzzle.puzzle = puzzle_data.to_json
                puzzle.sanitize_imported_data

            end

            pack.worksheet_url = worksheet.human_url

        rescue DataImporterError => e
            Rails.logger.error e.message
        rescue StandardError => e
            Rails.logger.error e.message
        end

        pack.published = false
        pack.save

        puzzle.data_processing = false
        puzzle.save

        pack.update_status_column
        pack.match_assets

        PackOps.delay.refresh_zip pack
        PackOps.set_sprite_sheet_status('stale') if pack.pack_type != ''
        PackOps.delay.refresh_pack_puzzle_game_positions

    end

    def self.get_pack_worksheet_url pack

        worksheet = DataImporter::get_worksheet pack
        return false if !worksheet

        pack.worksheet_url = worksheet.human_url
        pack.save

        return true

    end

    def self.relink_to_google_sheet pack

        begin

            worksheet = DataImporter::get_worksheet pack
            pack.worksheet_url = worksheet.human_url
            pack.save

        rescue DataImporterError => e
            Rails.logger.error e.message

        rescue StandardError => e
            Rails.logger.error e.message
        end

    end

    private

    def self.get_worksheet pack

        session = start_session
        pack_sheet = session.file_by_title(pack.google_sheet_file_name)

        raise DataImporterError.new('Cannot find pack') if !pack_sheet

        worksheet = pack_sheet.worksheet_by_title(pack.pack_code)

        raise DataImporterError.new('Cannot find worksheet') if !worksheet

        worksheet

    end

    def self.start_session

        service_account = Rails.root.join('tmp', 'service_account.json').to_s
        service_string = '{"type": "service_account","project_id": "word-laces","private_key_id": "[GDRIVE_PRIVATE_KEY_ID]","private_key": "[GDRIVE_PRIVATE_KEY]","client_email": "word-laces-service-account@word-laces.iam.gserviceaccount.com","client_id": "[GDRIVE_CLIENT_ID]","auth_uri": "https://accounts.google.com/o/oauth2/auth","token_uri": "https://oauth2.googleapis.com/token","auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/word-laces-service-account%40word-laces.iam.gserviceaccount.com"}'
        service_string.sub! '[GDRIVE_PRIVATE_KEY_ID]', ENV['GDRIVE_PRIVATE_KEY_ID']
        service_string.sub! '[GDRIVE_PRIVATE_KEY]', ENV['GDRIVE_PRIVATE_KEY']
        service_string.sub! '[GDRIVE_CLIENT_ID]', ENV['GDRIVE_CLIENT_ID']

        open(service_account, 'w') do |file|
            file.write service_string
        end

        GoogleDrive::Session.from_service_account_key(service_account)

    end

    def self.parse_titles title_row

        languages = Language.all
        parsed_titles = []

        title_row.each do |title|
            
            code, special = title.split('_')

            found_lang = languages.index do |lang|
                lang.code == code
            end

            if found_lang
                parsed_titles << {
                    code: languages[found_lang].code,
                    special: special
                }
            else
                parsed_titles << nil
            end

        end

        parsed_titles

    end

    def self.parse_worksheet worksheet

        rows = worksheet.rows
        titles = DataImporter::parse_titles rows[2]

        puzzles = []
        puzzle_keys = []
        puzzle = false

        lang_en = Language::CODE_ENGLISH

        rows[3..-1].each_with_index do |row, row_index|

            has_answer = false
            image = row[2].strip

            is_last_row = row_index == rows.length - 4

            if image != '' || is_last_row

                if puzzle

                    if puzzle[lang_en] && puzzle[lang_en]['difficulty']

                        zero_difficulties = puzzle[lang_en]['difficulty'].select{ |dif| dif > 0 }.length == 0

                        if zero_difficulties && !is_last_row
                            puzzle[lang_en].delete 'difficulty'
                        end

                    end

                    puzzles << puzzle
                    puzzle_keys << puzzle[:image]
                end
                
            end

            if image != ''
                puzzle = {image: image}
            end

            if puzzle

                row[3..-1].each_with_index do |column, column_index|
                    real_column_index = column_index + 3
                    title = titles[real_column_index]
                    
                    if !title.nil?
                        type = title[:special] || 'answers'
                        lang = title[:code]

                        if type == 'difficulty' && column == '' && has_answer
                            column = '0'
                        end

                        if column != '' && !title.nil?

                            puzzle[lang] = {} if !puzzle[lang]

                            column = (type == 'difficulty') ? column.to_f : column.strip
                            column = 0 if column === 0.0
                            puzzle[lang][type] = [] if !puzzle[lang][type]
                            
                            if type == 'caption'
                                puzzle[lang][type] = column
                            else
                                puzzle[lang][type] << column
                            end

                            has_answer = true if type == 'answers'

                        end
                    
                    end

                end

                if is_last_row && puzzle[lang_en] && puzzle[lang_en]['difficulty'] == 0 && zero_difficulties
                    puzzle[lang_en].delete 'difficulty'
                end

                # if the last puzzle has only one line in it
                if image != '' && row_index == rows.length - 4
                    puzzles << puzzle
                    puzzle_keys << puzzle[:image]
                end

            end

        end

        [puzzles, puzzle_keys]

    end

end