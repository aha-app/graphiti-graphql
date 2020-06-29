require "simplecov"
SimpleCov.start do
  add_filter "spec/"
end

require "bundler/setup"
require "graphiti"
require "graphiti-graphql"
require "graphiti_spec_helpers/rspec"
require "byebug"
require "database_cleaner-active_record"

require_relative "support/matchers"

Graphiti::Resource.autolink = false

Graphiti.setup!

RSpec.configure do |config|
  config.include GraphitiSpecHelpers::RSpec
  config.include GraphitiSpecHelpers::Sugar

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with :truncation
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require "kaminari"
require "active_record"
require "graphiti/adapters/active_record"
ActiveRecord::Migration.verbose = false
ActiveRecord::Base.establish_connection adapter: "sqlite3",
                                        database: ":memory:"
Dir[File.dirname(__FILE__) + "/fixtures/**/*.rb"].sort.each(&method(:require))
