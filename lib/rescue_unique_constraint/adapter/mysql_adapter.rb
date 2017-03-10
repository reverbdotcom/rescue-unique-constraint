module RescueUniqueConstraint
  module Adapter
    class MysqlAdapter
      def index_error?(index, error_message)
        error_message[/#{index.name}/]
      end
    end
  end
end
