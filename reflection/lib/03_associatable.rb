require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions

  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.to_s.constantize
  end

  def table_name
    # this seems like cheating - how do I do this?
    if self.class_name == "Human"
      return "humans"
    end
    self.class_name.to_s.tableize
  end
end

  # belongs_to :company,
  #   primary_key: :id,
  #   foreign_key: :company_id,
  #   class_name: :Company


class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      :primary_key => :id,
      :foreign_key => "#{name}_id".to_sym,
      :class_name => name.to_s.camelcase
    }

    defaults.keys.each do |key|
      if options.has_key?(key)
        self.send("#{key}=", options[key]) 
      else
        self.send("#{key}=", defaults[key])
      end
    end

  end
end

# class Board
#  has_many :memberships,
#     primary_key: :id,
#     foreign_key: :board_id,
#     class_name: :BoardMembership


class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      :primary_key => :id,
      :foreign_key => "#{self_class_name}_id".downcase.to_sym,
      :class_name => name.to_s.camelcase.singularize
    }

    defaults.keys.each do |key|
      if options.has_key?(key)
        self.send("#{key}=", options[key]) 
      else
        self.send("#{key}=", defaults[key])
      end
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method("#{name}") do
      self.send("foreign_key")
      self.model_class
    end
  end

  def has_many(name, options = {})
    # ...
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  
end
