module Positionable

  extend ActiveSupport::Concern

  included do
    before_create :set_initial_position

    default_scope { order(:position) }
  end

  module ClassMethods

    def positionable_scope *fields
      define_singleton_method(:positionable_scope_fields) { fields }
    end

    def set_positions ids, start_index = 0
      ids.split(',').each_with_index do |id, i|
        p = self.find(id)
        p.position = i + start_index
        p.save
      end
    end

    def set_position id, pos

      p = self.find(id)
      pp = self.all

      if self.respond_to? :positionable_scope_fields
        fields = self.positionable_scope_fields
        fields.each do |f|
          pp = pp.where(f.to_s + ' = ?', p.send(f))
        end
      end

      pp = pp.to_a
      index = pp.find_index {|item| item.id == id}

      pp.slice! index, 1
      pp.insert pos, p

      puts pp.inspect

      pp.each_with_index do |p, i|
        puts p.inspect
        p.position = i
        p.save
      end
    end

  end

  def set_initial_position
    return if !self.position.blank?

    klass = self.class.name.constantize
    c = klass.all

    if klass.respond_to? :positionable_scope_fields
      fields = klass.positionable_scope_fields
      fields.each do |f|
        next if !self.send(f)
        c = c.where(f.to_s + ' = ?', self.send(f))
      end
    end

    self.position = c.length
  end

end
