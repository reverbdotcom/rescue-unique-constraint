require 'rescue_unique_constraint/version'
require 'rescue_unique_constraint/adapter/postgresql_adapter'
require 'rescue_unique_constraint/adapter/sqlite_adapter'
require 'active_record'

# Module which will rescue ActiveRecord::RecordNotUnique exceptions
# and add errors for indexes that are registered with
# rescue_unique_constraint(index:, field:)
module RescueUniqueConstraint
  # handles storing and matching [index, field] pairs to exceptions
  class RescueHandler
    def initialize(model)
      @model = model
      @indexes_to_rescue_on = []
    end

    def add_index(index, field)
      indexes_to_rescue_on << [index, field]
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
        when :postgresql
          Adapter::PostgresqlAdapter.new
        when :sqlite
          Adapter::SqliteAdapter.new
        else
          raise "Database (#{database_name}) not supported"
        end
      )
    end

    def database_name
      model.connection.adapter_name.downcase.to_sym
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  # will automatically add these methods to the models which include this module
  module ClassMethods
    # rubocop:disable MethodLength I only want one method polluting the model
    def index_rescue_handler
      @index_rescue_handler ||= RescueUniqueConstraint::RescueHandler.new(self)
    end

    def rescue_unique_constraint(index:, field:)
      unless method_defined?(:create_or_update_with_rescue)
        define_method(:create_or_update_with_rescue) do
          begin
            create_or_update_without_rescue
          rescue ActiveRecord::RecordNotUnique => e
            self.class.index_rescue_handler.matching_indexes(e).each do |matching_index|
              errors.add(matching_index[1], :taken)
            end
            return false
          end
          true
        end

        alias_method :create_or_update_without_rescue, :create_or_update
        alias_method :create_or_update, :create_or_update_with_rescue
      end
      index_rescue_handler.add_index(index, field)
    end
  end
end
