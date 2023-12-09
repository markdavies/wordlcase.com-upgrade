class AppConfig < ActiveRecord::Base

  before_create :confirm_singularity
  
  # has_attached_file :puzzle_sheets,
  #   url: "#{Rails.env}/packs/puzzle_sheets.:extension",
  #   path: "#{Rails.env}/packs/puzzle_sheets.:extension"

  # validates_attachment_content_type :puzzle_sheets, 
  # content_type: [ 'application/zip', 'application/octet-stream' ], 
  # message: 'is invalid. Only zips permitted'

  # validates_attachment_size :puzzle_sheets,
  # in: 0..75.megabytes,
  # message: 'is too large. Should be no larger than 75MB'

  has_one_attached :puzzle_sheets

  def self.get
    c = AppConfig.first
    if !c
      c = AppConfig.new
      c.save
    end
    c
  end

  private

  def confirm_singularity
    raise Exception.new("There can be only one.") if AppConfig.count > 0
  end

end