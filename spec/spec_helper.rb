# frozen_string_literal: true

require "active_record"
require "query_explainer"

DB_CONNECTION = {
  adapter: "mysql2",
  host: ENV.fetch("DB_HOST", "127.0.0.1"),
  port: Integer(ENV.fetch("DB_PORT", "3306")),
  username: ENV.fetch("DB_USERNAME", "root"),
  password: ENV.fetch("DB_PASSWORD", "proton")
}.freeze

DB_NAME = ENV.fetch("DB_NAME", "query_explainer_test")

# The gem parses MySQL's EXPLAIN output, so there is nothing worth testing
# against a stub. Build a schema whose indexes we control instead.
ActiveRecord::Base.establish_connection(**DB_CONNECTION)
ActiveRecord::Base.connection.execute("CREATE DATABASE IF NOT EXISTS `#{DB_NAME}`")
ActiveRecord::Base.establish_connection(**DB_CONNECTION, database: DB_NAME)

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table :widgets, force: true do |t|
    t.string :name
    # limit keeps the index under MySQL 5.6's 767 byte maximum on utf8mb4
    t.string :code, limit: 64
    t.index :code
  end
end

# Stands in for ActiveSupport::Notifications::Event
NotificationEvent = Struct.new(:payload, :duration)

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
