module RescueUniqueConstraint
  module Adapter
    class SqliteAdapter
      def initialize(table_name)
        @table_name = table_name
      end

      # Sample error message returned by ActiveRecord for Sqlite Unique exception:
      # 'SQLite3::ConstraintException: UNIQUE constraint failed: things.code, things.score: INSERT INTO "things" ("name", "test", "code", "score") VALUES (?, ?, ?, ?)'
      #
      # Step1: extract column names from above message on which unique constraint failed.
      # Step2: Check if this index's field is among those columns.
      def index_error?(index, error_message)
        column_names = error_message.scan(%r{(?<=#{@table_name}\.)\w+})
        column_names.include?(index.field)
      end
    end
  end
end
