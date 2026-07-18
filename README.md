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

### Outside Rails

```ruby
QueryExplainer.subscribe
QueryExplainer.logger = MyLogger.new
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
