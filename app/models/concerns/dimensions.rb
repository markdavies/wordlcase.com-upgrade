module Dimensions

  extend ActiveSupport::Concern

  included do

  end
  
  module ClassMethods

    def extract_dimensions_for *fields

      define_method(:extract_dimensions_field_list) { fields }

      before_save :extract_dimensions

      fields.each do |f|
        serialize (f.to_s+"_dimensions"), Hash

        class_eval do

          [:width, :height].each do |axis|
            define_method("#{f}_#{axis}") do
              return send(f.to_s+"_dimensions")[axis]
            end
          end

          define_method("#{f}_is_portrait?") do
            dims = send(f.to_s+"_dimensions")
            return dims[:width] <= dims[:height]
          end

          define_method("#{f}_is_landscape?") do
            dims = send(f.to_s+"_dimensions")
            return dims[:width] > dims[:height]
          end


        end

      end

      class_eval do

        def extract_dimensions

          extract_dimensions_field_list.each do |f|

            tempfile = send(f).queued_for_write[:original]
            unless tempfile.nil?
              geometry = Paperclip::Geometry.from_file(tempfile)
              self.send(f.to_s+"_dimensions=", {width: geometry.width.to_i, height: geometry.height.to_i})
            end

          end

        end

      end

    end

  end
  
  
end
