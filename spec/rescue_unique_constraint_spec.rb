require 'active_record'
require 'rescue_unique_constraint'

describe RescueUniqueConstraint do
  before do
    ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
    ActiveRecord::Schema.verbose = false
    ActiveRecord::Schema.define(:version => 1) do
      create_table :things do |t|
        t.string :name
        t.string :test
      end

      add_index :things, :name, unique: true, name: "idx_things_on_name_unique"
      add_index :things, :test, unique: true, name: "idx_things_on_test_unique"
    end
  end

  class Thing < ActiveRecord::Base
    include RescueUniqueConstraint
    rescue_unique_constraint index: "idx_things_on_name_unique", field: "name"
    rescue_unique_constraint index: "idx_things_on_test_unique", field: "test"
  end

  it "rescues unique constraint violations as activerecord errors" do
    thing = Thing.create(name: "foo", test: 'bar')
    dupe = Thing.new(name: "foo", test: 'bar')
    expect(dupe.save).to eql false
    expect(dupe.errors[:name].first).to match /taken/
    expect(dupe.errors[:test].first).to match /taken/
  end
end
