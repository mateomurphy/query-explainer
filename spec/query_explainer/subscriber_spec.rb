# frozen_string_literal: true

require "spec_helper"

RSpec.describe QueryExplainer::Subscriber do
  let(:recorder) do
    Class.new do
      attr_reader :logged

      def initialize(_logger) = @logged = []

      def log(explainer) = @logged << explainer.query
    end
  end

  let(:subscriber) { described_class.new(formatter: recorder) }
  let(:logged) { subscriber.formatter.logged }

  def event(sql, name: "Widget Load", duration: 1.0)
    NotificationEvent.new({ sql: sql, name: name }, duration)
  end

  it "logs a select with no usable index" do
    subscriber.call(event("SELECT * FROM widgets WHERE name = 'x'"))

    expect(logged.size).to eq(1)
  end

  it "ignores queries that use an index" do
    subscriber.call(event("SELECT * FROM widgets WHERE code = 'x'"))

    expect(logged).to be_empty
  end

  it "ignores writes" do
    subscriber.call(event("UPDATE widgets SET name = 'x'"))

    expect(logged).to be_empty
  end

  it "ignores Rails' own internal queries" do
    subscriber.call(event("SELECT * FROM widgets WHERE name = 'x'", name: "SCHEMA"))
    subscriber.call(event("SELECT * FROM widgets WHERE name = 'x'", name: nil))

    expect(logged).to be_empty
  end

  it "logs an N+1 only once" do
    5.times do |i|
      subscriber.call(event("SELECT * FROM widgets WHERE name = 'x#{i}' LIMIT 1"))
    end

    expect(logged.size).to eq(1)
  end

  it "still logs a genuinely different query" do
    subscriber.call(event("SELECT * FROM widgets WHERE name = 'x'"))
    subscriber.call(event("SELECT * FROM widgets ORDER BY name"))

    expect(logged.size).to eq(2)
  end

  it "picks up a logger assigned after it was built" do
    subscriber = described_class.new
    custom = Logger.new(StringIO.new)
    QueryExplainer.logger = custom

    expect(subscriber.formatter.logger).to be(custom)
  ensure
    QueryExplainer.logger = nil
  end

  it "swallows errors so it cannot break the query it is observing" do
    expect { subscriber.call(event("SELECT * FROM table_that_does_not_exist")) }
      .not_to raise_error

    expect(logged).to be_empty
  end
end
