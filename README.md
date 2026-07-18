# QueryExplainer

Finds missing indexes by running `EXPLAIN` on the queries your app actually
makes, and logging the ones MySQL had to resolve without a usable index.

```
┌────────────────────────────────────────┐
│ SELECT `bios`.*                        │
│   FROM `bios`                          │
│   ORDER BY `bios`.`created_at` ASC     │
│   LIMIT 3                              │
│ 0.3736 ms                              │
│ bios: Using filesort, No possible keys │
└────────────────────────────────────────┘
```

Unlike static analysis, this only reports indexes missing on paths your code
really exercises, with the query that got there.

MySQL only — it parses MySQL's `EXPLAIN` output format.

## Installation

```ruby
group :development do
  gem "query_explainer"
end
```

Keep it in the `:development` group. Explaining every query doubles the queries
the database sees, and the gem is not built for production traffic.

## Usage

Set `EXPLAIN_QUERIES` and start your app:

```bash
EXPLAIN_QUERIES=1 bin/rails server
```

A Railtie subscribes automatically, so there is nothing to add to an
initializer. Exercise the pages you care about and watch the log.

A query is reported when it is a `SELECT` and `EXPLAIN` says MySQL either had no
index available (`No possible keys`), had one but did not use it (`No key`), or
had to sort or buffer rows itself (`Using filesort`, `Using temporary`).

Repeated queries are reported once. Literals are collapsed before comparing, so
an N+1 across 100 rows prints one table, not 100.

### Configuring the logger

Warnings go to `$stdout`. To send them elsewhere:

```ruby
QueryExplainer.logger = MyLogger.new
```

### Without Rails

Rails is not required, but ActiveRecord is — the gem explains the queries
ActiveRecord emits, and reads them from ActiveSupport notifications. All Rails
itself adds is a Railtie that calls `subscribe` for you. Without it, subscribe
by hand and skip the `EXPLAIN_QUERIES` check if you want it always on:

```ruby
require "query_explainer"

QueryExplainer.subscribe if QueryExplainer.enabled?
```

## Development

Specs run against real MySQL, since parsing real `EXPLAIN` output is the whole
job. Point them at a server with `DB_HOST`, `DB_PORT`, `DB_USERNAME`,
`DB_PASSWORD` and `DB_NAME`; the defaults match a local Docker MySQL. The
`query_explainer_test` database and its schema are created for you.

```bash
bin/setup
bundle exec rspec
bundle exec rubocop
```

## License

Available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
