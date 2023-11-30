module Sluggable

  extend ActiveSupport::Concern

  included do

    before_validation :set_slug

  end
  
  module ClassMethods

    def slugs *fields
      define_method(:slugs_fields) { fields }
    end

  end

  def set_slug

    self.slug = slugs_fields.collect do |f|
      self.send(f).to_s
    end.join('-').parameterize

  end

end
