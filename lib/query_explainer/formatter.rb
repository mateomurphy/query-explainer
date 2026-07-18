# frozen_string_literal: true

require "terminal-table"
require "niceql"

module QueryExplainer
  # Renders an explained query and its warnings as a bordered table.
  class Formatter
    def initialize(logger = nil)
      @logger = logger
    end

    # Resolved late: under Rails the Railtie subscribes during boot, so a host
    # setting QueryExplainer.logger always does so after this was constructed.
    def logger
      @logger || QueryExplainer.logger
    end

    def log(explainer)
      rows = [
        [formatted_query(explainer.query)],
        ["#{explainer.duration.round(4)} ms"]
      ]

      explainer.warnings.each do |table, messages|
        rows << ["#{table}: #{messages.join(", ")}"]
      end

      logger.warn("\n#{Terminal::Table.new(rows: rows, style: style).render}")
    end

    private

    # Colour codes are noise once the output is piped to a file or CI log
    def formatted_query(query)
      Niceql::Prettifier.prettify_sql(query, $stdout.tty?)
    end

    def style
      { border: :unicode }
    end
  end
end
