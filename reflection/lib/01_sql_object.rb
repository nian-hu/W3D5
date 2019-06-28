require_relative 'db_connection'
require 'active_support/inflector'
require "byebug"
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns 

    col = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM  
        #{self.table_name}
    SQL

    @columns = col.first.map!(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column|
      define_method("#{column}") do 
        self.attributes[column]       # we want this to be a symbol, not a string!
      end

      define_method("#{column}=") do |val| 
        self.attributes[column] = val   # we call self.attributes because @attributes needs to be lazily initialized (can't just summon @attributes)
      end 
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.downcase.pluralize
  end

  def self.all
    arr = DBConnection.execute(<<-SQL)   
      SELECT
        #{self.table_name}.*
      FROM  
        #{self.table_name}
    SQL
    # array of hashes

    self.parse_all(arr)
  end

  def self.parse_all(results)   # array of hashes
    results.map do |result|    # it's a hash
      self.new(result)
    end
  end

  def self.find(id)
    arr = DBConnection.execute(<<-SQL, id)   
      SELECT
        #{self.table_name}.*
      FROM  
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
    SQL

    self.parse_all(arr).first
  end

  # when you parse it, you get the whole thing
  # you only want the FIRST

  def initialize(params = {})     # accepts a hash
    params.each do |name, value|     # isn't the attr_name always a symbol?
      new_name = name.to_sym
      raise "unknown attribute '#{new_name}'" unless self.class.columns.include?(new_name) 
          # self.columns is a CLASS method, so call it using self.class.columns
          # we don't want to refer to SQLObject.columns either
      self.send("#{new_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column|    
      # we do self.class because we are currently in an instance method 
      self.send(column)           
      # returns JUST the value from getter method
    end
  end

  def insert
    col_names = self.class.columns.drop(1).join(", ")    # we don't want ID column
    n = self.class.columns.count - 1

    # question_marks = [] 
    # n.times do          
    #   [] << "?"
    # end
    
    question_marks = ["?"] * n 
    question_marks = question_marks.join(", ") # turns this into a string          
                                      # drop one first, then splat
    # debugger
    DBConnection.execute(<<-SQL, *attribute_values.drop(1) )    
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES 
        (#{question_marks})
        
    SQL

    # this will return the ID, call setter method
    self.id = DBConnection.last_insert_row_id

  end

  def update
    cols = self.class.columns.drop(1).map do |column|
      "#{column} = ?"
    end

    cols = cols.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values.drop(1))    
      UPDATE
        #{self.class.table_name}
      SET 
        #{cols}
      WHERE
        id = #{self.class.columns.first}
    SQL

    # my mistake was doing #{self.class.columns.first} = ?
  end

  def save
    # I was overthinking it! can just call getter method
    if id.nil?
      self.insert 
    else 
      self.update
    end
  end
end
