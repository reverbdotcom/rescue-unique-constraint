module RescueUniqueConstraint
  # Handles storing and matching [index, field] pairs to exceptions
  class RescueHandler
    def initialize(model)
      @model = model
      @indexes_to_rescue_on = []
    end

    def add_index(index, field)
      indexes_to_rescue_on << Index.new(index, field)
    end

    def matching_indexes(e)
      indexes = indexes_to_rescue_on.select do |index|
        database_adapter.index_error?(index, e.message)
      end
      raise e unless indexes.any?
      indexes
    end

    private

    attr_reader :indexes_to_rescue_on, :model

    def database_adapter
      @_database_adapter ||= (
        case database_name
        when :mysql2
          Adapter::MysqlAdapter.new
        when :postgresql
          Adapter::PostgresqlAdapter.new
        when :sqlite
          Adapter::SqliteAdapter.new(@model.table_name)
        else
          raise "Database (#{database_name}) not supported"
        end
      )
    end

    def database_name
      model.connection.adapter_name.downcase.to_sym
    end
  end
end
