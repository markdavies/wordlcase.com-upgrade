module Positioner

  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods

    def positions *field

      options = field.last.class == Hash ? field.last : {}
      field = field.first

      singular = field.to_s.singularize
      klass = singular.classify.constantize

      class_eval do

        after_save "set_#{singular}_positions"

        define_method("set_#{singular}_positions") do
          
          positions = self.send("#{singular}_positions")
          position_scopes = self.send("#{singular}_position_scopes")
          position_scope_name = self.send("#{singular}_position_scope_name")

          next if !positions

          f = options[:through] ? options[:through] : field
          fid = options[:through] ? "#{singular}_id" : "id"

          positions.each_with_index do |p, i|

            p = p.split(',').map(&:to_i)
            existing = self.send(f)

            if position_scopes && position_scope_name
              existing = existing.where("#{position_scope_name} = '#{position_scopes[i]}'")
            end

            existing.each do |i|
              i.position = p.index i.send(fid)
              i.save
            end

          end

        end

      end

      attr_accessor "#{singular}_positions"
      attr_accessor "#{singular}_position_scopes"
      attr_accessor "#{singular}_position_scope_name"

    end

  end

end
