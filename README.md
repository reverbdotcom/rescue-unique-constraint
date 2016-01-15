# RescueUniqueConstraint

ActiveRecord doesn't do a great job of rescuing ActiveRecord::RecordNotUnique
violations resulting from a duplicate entry on a database level unique constraint.

This gem automatically rescues the error and instead adds a validation error
on the field in question, making it behave as if you had a normal uniqueness
validation.

Note that if you have only a unique constraint in the database and no uniqueness validation in ActiveRecord, it
is possible for your object to validate but then fail to save.

See Usage for more info.

## Installation

Add this line to your application's Gemfile:

    gem 'rescue_unique_constraint'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rescue_unique_constraint

## Usage

Assuming you've added unique index:

    class AddIndexToThing < ActiveRecord::Migration
      disable_ddl_transaction!

      def change
        add_index :things, :somefield, unique: true, algorithm: :concurrently, name: "my_unique_index"
      end
    end

Before:

    class Thing < ActiveRecord::Base
    end

    thing = Thing.create(somefield: "foo")
    dupe = Thing.create(somefield: "foo")
    => raises ActiveRecord::RecordNotUnique

Note that if you have `validates :uniqueness` in your model, it will prevent
the RecordNotUnique from being raised in _some_ cases, but not all, as race
conditions between multiple processes will still cause duplicate entries to
enter your database.

After:

    class Thing < ActiveRecord::Base
      rescue_unique_constraint index: "my_unique_index", field: "somefield"
    end

    thing = Thing.create(somefield: "foo")
    dupe = Thing.create(somefield: "foo")
    => false
    thing.errors[:somefield] == "somefield has already been taken"
    => true

## Testing

You'll need a database that supports unique constraints.
This gem has been tested with PostgreSQL and SQLite only.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/rescue_unique_constraint/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
