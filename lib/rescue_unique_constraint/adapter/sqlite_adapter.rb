module RescueUniqueConstraint
  module Adapter
    class SqliteAdapter
      def index_error?(index, error_message)
        error_message[/UNIQUE.*#{index.field}/]
      end
    end
  end
end
