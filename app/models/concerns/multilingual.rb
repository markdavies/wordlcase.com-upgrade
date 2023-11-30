module Multilingual

  extend ActiveSupport::Concern
  require "exceptions"

  included do
  end
  
  module ClassMethods

    def multilingual_fields *fields

      define_method(:multilingual_field_list) { fields }

      fields.each do |f|

        serialize f

        define_singleton_method "find_by_#{f}" do |val, lang=I18n.locale|
          where("#{self.name.tableize}.slug like E'%:#{lang}: #{val}\n%'").first
        end

        class_eval do

          define_method("#{f}=") do |args|

            args = args.symbolize_keys rescue args

            if args.class == Hash

              args.reject! do |key, value|
                !I18n.available_locales.include?(key)
              end

              write_attribute f, args

            else
              
              val = args.kind_of?(Array) ? args.first : args
              lang = args.kind_of?(Array) ? args[1] : I18n.locale

              raise Exceptions::UnsupportedLanguageException if !I18n.available_locales.include?(lang)
              
              hash = read_attribute(f)
              hash = {} if hash.class != Hash
              hash[lang] = val

              write_attribute f, hash

            end

          end

          define_method(f) do |lang = nil|

            hash = read_attribute(f)
            hash = {} if hash.class != Hash
            lang = I18n.locale if !lang
            hash[lang]

          end          

        end

      end

    end    

    def multilingual_slug column

      define_method(:slug_source) { column }
      before_validation :multilingual_slug_save
      validate :multilingual_slug_uniqueness

      class_eval do

        def multilingual_slug_save

          raise Exceptions::FieldNotMultiLingual if !multilingual_field_list.include?(slug_source)

          hash = read_attribute(slug_source) || send(slug_source) || {}
          hash.each do |lang, val|
            self.slug = val.parameterize, lang.to_sym
          end

        end

        def multilingual_slug_uniqueness

          hash = self.read_attribute(:slug)

          return true if !hash

          where = []
          hash.each do |key, val|

            # this is obviously postgres specific, but not sure how to search for this without the string literal "E"
            where << "slug like E'%:#{key.to_s}: #{val}\n%'"

          end

          c = self.class.name.constantize
          where = '(' + where.join(' or ') + ')'
          where += " and id != #{self.id}" if !self.new_record?

          self.errors.add :slug, 'must be unique in every language' if c.where(where).length > 0

        end

      end

    end

  end

end
