require 'active_record'
require 'rescue_unique_constraint'

describe RescueUniqueConstraint do
  before :all do
    ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
    ActiveRecord::Schema.verbose = false
    ActiveRecord::Schema.define(:version => 1) do
      create_table :things do |t|
        t.string :name
        t.string :test
        t.integer :code
        t.integer :score
      end

      add_index :things, :name, unique: true, name: "idx_things_on_name_unique"
      add_index :things, :test, unique: true, name: "idx_things_on_test_unique"
      add_index :things, [:code, :score], unique: true, name: "idx_things_on_code_and_score_unique"
    end
  end

  class Thing < ActiveRecord::Base
    include RescueUniqueConstraint
    rescue_unique_constraint index: "idx_things_on_name_unique", field: "name"
    rescue_unique_constraint index: "idx_things_on_test_unique", field: "test"
    rescue_unique_constraint index: "idx_things_on_code_and_score_unique", field: "score"
  end

  before :each do
    Thing.destroy_all
  end

  it "rescues unique constraint violations as activerecord errors" do
    thing = Thing.create(name: "foo", test: 'bar', code: 123, score: 1000)
    dupe = Thing.new(name: "foo", test: 'baz', code: 456, score: 2000)
    expect{ dupe.save }.to raise_error(ActiveRecord::RecordNotUnique)
    expect(dupe.errors.messages.keys).to contain_exactly(:name)
    expect(dupe.errors[:name].first).to match /has already been taken/
  end

  it "adds error message to atrribute which caused unique-voilation" do
    thing = Thing.create(name: "foo", test: 'bar', code: 123, score: 1000)
    dupe = Thing.new(name: "lorem", test: 'bar', code: 456, score: 2000)
    expect{ dupe.save }.to raise_error(ActiveRecord::RecordNotUnique)
    expect(dupe.errors.messages.keys).to contain_exactly(:test)
    expect(dupe.errors[:test].first).to match /has already been taken/
  end

  context "When unique contraint is voilated by a composite index" do
    it "adds error message to user defined atrribute" do
      thing = Thing.create(name: "foo", test: 'bar', code: 123, score: 1000)
      dupe = Thing.new(name: "lorem", test: 'ipsum', code: 123, score: 1000)
      expect{ dupe.save }.to raise_error(ActiveRecord::RecordNotUnique)
      expect(dupe.errors.messages.keys).to contain_exactly(:score)
      expect(dupe.errors[:score].first).to match /has already been taken/
    end
  end
end
