module RescueUniqueConstraint
  class Index
    attr_reader :name, :field
    def initialize(name, field)
      @name = name
      @field = field
    end
  end
end
