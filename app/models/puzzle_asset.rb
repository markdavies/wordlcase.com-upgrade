class PuzzleAsset < ActiveRecord::Base

  belongs_to :pack

  validates_presence_of :pack_id

  before_save :downcase_image_id

  # has_attached_file :image, styles: lambda { |att| att.instance.get_convert_sizes }

  # validates_attachment_content_type :image, 
  # content_type: [ 'image/jpg', 'image/jpeg' ], 
  # message: 'is invalid. Only jpg format is permitted'

  # validates_attachment_size :image,
  # in: 0..10.megabytes,
  # message: 'is too large. Should be no larger than 10MB'
  has_one_attached :image

  before_save :check_image_reprocess

  def downcase_image_id
    self.image_id = self.image_id.downcase
  end
  
  def image_slug_changed?
    image_id_changed?
  end

  def style_file_name attachment, style

    # use the old location for the original style, this allows us to reprocess and still know where the source is currently kept
    # if pack_id_changed? && style == :original
    #   pack_code = Pack.find(pack_id_was).pack_code
    # else
    #   pack_code = pack.pack_code
    # end

    str = "#{pack.pack_code}/"

    return "#{str}#{id}_original" if style == :original

    str << 'thumb_' if style.to_s.index('thumbnail') != nil
    str << self.image_id.parameterize

    str

  end

  def get_convert_sizes

    config = AppConfig.get
    quality = "-quality #{config.image_quality}"

    {
      square: { 
        geometry: '200x200#',
        convert_options: quality
      },
      large: { 
        geometry: '768x768#',
        convert_options: quality 
      },
      thumbnail: { 
        geometry: '100x100#',
        convert_options: quality
      }
    }
  end

  def check_image_reprocess
    
    # if (image_slug_changed? && image.present? && !image_updated_at_changed?)

    #   p = self.class.find(id)
    #   old_keys = p.image.styles.keys.collect do |style|
    #     p.image.path(style)
    #   end

    #   self.delay.reprocess_image
    #   self.update_column(:image_reprocessing, true)

    #   if ENV['FOG_DIRECTORY']
    #     s3 = get_s3
    #     s3.delete_multiple_objects ENV['FOG_DIRECTORY'], old_keys

    #   end

    # end

  end

  def move_and_reprocess_image

    return false if !pack_id_changed?

    old_pack_code = Pack.find(pack_id_was).pack_code
    new_pack_code = pack.pack_code

    new_path = image.path(:original)
    old_path = new_path.sub new_pack_code, old_pack_code

    if ENV['FOG_DIRECTORY']
      s3 = get_s3
      s3.copy_object(ENV['FOG_DIRECTORY'], old_path, ENV['FOG_DIRECTORY'], new_path)
    else
      require 'fileutils'
      FileUtils.mv(old_path, new_path)
    end

    image.reprocess!

  end

  def reprocess_image
    image.reprocess!
    self.update_column(:image_reprocessing, false)
  end

  private

  def get_s3
    Fog::Storage.new({
      :provider              => 'AWS',
      :aws_access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
      :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    })
  end

end
