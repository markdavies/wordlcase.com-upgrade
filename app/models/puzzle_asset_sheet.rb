class PuzzleAssetSheet < ActiveRecord::Base
  
    IMAGES_PER_SPRITE_SHEET = 400

    if ENV['FOG_DIRECTORY']
        url = "#{Rails.env}/packs/:style_file_name.:extension"
        path = "#{Rails.env}/packs/:style_file_name.:extension"
    else
        url = '/static/packs/:style_file_name.:extension'
        path = ':rails_root/public/:url'
    end
      

    has_attached_file :image,
        url: url,
        path: path

    validates_attachment_content_type :image, 
        content_type: [ 'image/jpg', 'image/jpeg' ], 
        message: 'is invalid. Only jpg format is permitted'

    validates_attachment_size :image,
        in: 0..5.megabytes,
        message: 'is too large. Should be no larger than 5MB'


    def style_file_name attachment, style
        return "thumbs_#{self.pack_type}_#{self.range_string}"
    end

    def range_string

        if self.pack_type == Pack::TYPE_DAILY
            return self.year.to_s

        else

            idx_start = self.position * PuzzleAssetSheet::IMAGES_PER_SPRITE_SHEET + 1
            idx_end = idx_start + PuzzleAssetSheet::IMAGES_PER_SPRITE_SHEET - 1

            return "#{sprintf('%04d', idx_start)}-#{sprintf('%04d', idx_end)}"

        end

    end

end
