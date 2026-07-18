# frozen_string_literal: true

module QueryExplainer
  # Runs EXPLAIN against a query and reports what MySQL had to do without an
  # index. Column names below are MySQL's EXPLAIN output format.
  class Explainer
    attr_reader :query, :duration

    # Extra values that describe normal operation rather than a problem
    IGNORE_EXTRAS = [
      "Using index",
      "Using where",
      "Using index condition"
    ].freeze

    def initialize(query, duration, connection: nil)
      @query = query
      @duration = duration
      @connection = connection
    end

    def select_query?
      query.start_with?("SELECT")
    end

    def explain_result
      @explain_result ||= connection.exec_query("EXPLAIN #{query}")
    end

    def warnings
      @warnings ||= explain_result.each_with_object({}) do |row, data|
        # only happens when the query cannot produce results
        next unless row["table"]

        table_warnings = extra_warnings(row) + index_warnings(row)

        data[row["table"]] = table_warnings unless table_warnings.empty?
      end
    end

    def warnings?
      !warnings.empty?
    end

    private

    def extra_warnings(row)
      row["Extra"].to_s.split("; ") - IGNORE_EXTRAS
    end

    def index_warnings(row)
      return ["No possible keys"] if blank?(row["possible_keys"])
      return ["No key"] if blank?(row["key"])

      []
    end

    def blank?(value)
      value.nil? || value.empty?
    end

    def connection
      @connection || ActiveRecord::Base.connection
    end
  end
end
