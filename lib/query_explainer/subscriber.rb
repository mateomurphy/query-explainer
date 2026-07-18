# frozen_string_literal: true

module QueryExplainer
  # ActiveSupport::Notifications subscriber for "sql.*" events.
  class Subscriber
    # Payload names Rails uses for its own bookkeeping queries
    IGNORE = %w[SCHEMA SQL].freeze

    # Stops a long-running dev server accumulating fingerprints forever
    MAX_SEEN = 1_000

    attr_reader :formatter

    def initialize(formatter: Formatter, logger: nil)
      @formatter = formatter.new(logger)
      @seen = Set.new
      @mutex = Mutex.new
    end

    def call(event)
      return unless user_payload?(event.payload)

      explainer = Explainer.new(event.payload[:sql], event.duration)
      return unless explainer.select_query?
      return unless first_occurrence?(explainer.query)
      return unless explainer.warnings?

      formatter.log(explainer)
    rescue StandardError => e
      # Never let a debugging aid break the query it is observing
      QueryExplainer.logger.debug("QueryExplainer failed: #{e.class}: #{e.message}")
    end

    private

    def user_payload?(payload)
      name = payload[:name]

      !name.nil? && !name.empty? && !IGNORE.include?(name)
    end

    # An N+1 differs only by its literals, so collapse them before comparing.
    # Without this a single N+1 prints one table per row.
    def first_occurrence?(query)
      fingerprint = query.gsub(/'[^']*'/, "?").gsub(/\b\d+\b/, "?")

      @mutex.synchronize do
        @seen.clear if @seen.size >= MAX_SEEN
        @seen.add?(fingerprint)
      end
    end
  end
end
