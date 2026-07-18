# frozen_string_literal: true

require "logger"
require "active_support/notifications"

require_relative "query_explainer/version"
require_relative "query_explainer/explainer"
require_relative "query_explainer/formatter"
require_relative "query_explainer/subscriber"

# Logs an EXPLAIN for MySQL queries that run without a usable index.
module QueryExplainer
  class Error < StandardError; end

  # Notification events to watch. Rails emits "sql.active_record".
  EVENT_PATTERN = /sql\./

  class << self
    attr_writer :logger

    # Explaining every query doubles the queries the database sees, so this is
    # opt-in per process rather than per environment.
    def enabled?
      value = ENV.fetch("EXPLAIN_QUERIES", nil)

      !value.nil? && !value.empty?
    end

    # Severity and timestamp prefixes only get in the way of a rendered table
    def logger
      @logger ||= Logger.new($stdout, formatter: ->(_severity, _time, _progname, msg) { "#{msg}\n" })
    end

    def subscribe
      ActiveSupport::Notifications.subscribe(EVENT_PATTERN, Subscriber.new)
    end
  end
end

require_relative "query_explainer/railtie" if defined?(Rails::Railtie)
