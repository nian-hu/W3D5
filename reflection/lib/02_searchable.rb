require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map do |key|
      "#{key} = ?"
    end

    where_line = where_line.join(" AND ")

    results = DBConnection.execute(<<-SQL, *params.values)    
      SELECT
        *
      FROM
        #{table_name} 
      WHERE
        #{where_line}
    SQL

    # also you don't need self.class in TABLE NAME
    # just table name itself
    # wh? because searchable is gonna be included in CLASS

    parse_all(results)    
    # remember to parse! 
    # if "where" gives you multiple results, it will store them in array
    # but we don't want that array-like structure! 
    # convert it to ruby object by parsing
  end
end

class SQLObject
  extend Searchable    # EXTEND
end
