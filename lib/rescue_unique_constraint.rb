require 'rescue_unique_constraint/version'
require 'rescue_unique_constraint/index'
require 'rescue_unique_constraint/rescue_handler'
require 'rescue_unique_constraint/adapter/mysql_adapter'
require 'rescue_unique_constraint/adapter/postgresql_adapter'
require 'rescue_unique_constraint/adapter/sqlite_adapter'
require 'active_record'

# Module which will rescue ActiveRecord::RecordNotUnique exceptions
# and add errors for indexes that are registered with
# rescue_unique_constraint(index:, field:)
module RescueUniqueConstraint
  def self.included(base)
    base.extend(ClassMethods)
  end

  # methods mixed into ActiveRecord class
  module ClassMethods
    def index_rescue_handler
      @_index_rescue_handler ||= RescueUniqueConstraint::RescueHandler.new(self)
    end

    def rescue_unique_constraint(index:, field:)
      unless method_defined?(:create_or_update_with_rescue)
        define_method(:create_or_update_with_rescue) do |*|
          begin
            create_or_update_without_rescue
          rescue ActiveRecord::RecordNotUnique => e
            self.class.index_rescue_handler.matching_indexes(e).each do |matching_index|
              errors.add(matching_index.field, :taken)
              throw :abort
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
