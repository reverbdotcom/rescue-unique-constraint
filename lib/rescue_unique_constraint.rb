require "rescue_unique_constraint/version"
require 'active_record'

module RescueUniqueConstraint
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def rescue_unique_constraint(index:, field:)
      define_method(:create_or_update_with_rescue) do
        begin
          create_or_update_without_rescue
        rescue ActiveRecord::RecordNotUnique => e
          case e.message
          when /#{index}/  # Postgres
            errors.add(field, :taken)
          when /UNIQUE.*#{field}/ # SQLite
            errors.add(field, :taken)
          else
            # This should not happen; we want to know if we forgot to handle some unique constraint
            raise e
          end
          false
        end
      end

      alias_method :create_or_update_without_rescue, :create_or_update
      alias_method :create_or_update, :create_or_update_with_rescue
    end
  end
end

ActiveRecord::Base.include(RescueUniqueConstraint)
