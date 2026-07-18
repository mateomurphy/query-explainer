# frozen_string_literal: true

require_relative "lib/query_explainer/version"

Gem::Specification.new do |spec|
  spec.name = "query_explainer"
  spec.version = QueryExplainer::VERSION
  spec.authors = ["Mateo Murphy"]
  spec.email = ["33degrees@gmail.com"]

  spec.summary = "Logs an EXPLAIN for MySQL queries that run without a usable index"
  spec.description = <<~DESC
    Subscribes to ActiveRecord SQL notifications and runs EXPLAIN on each SELECT,
    logging the ones MySQL had to resolve without a usable index or with a
    filesort. Repeated queries are collapsed so an N+1 reports once. Intended for
    development use: explaining every query doubles the queries the database sees.
  DESC
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # TODO: set homepage, source_code_uri, changelog_uri and allowed_push_host
  # once hosting is decided. Until then the gem is consumed via path:/git:.

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.0"
  spec.add_dependency "niceql", "~> 0.6"
  spec.add_dependency "terminal-table", "~> 4.0"
end
