# frozen_string_literal: true

require "spec_helper"

RSpec.describe QueryExplainer::Explainer do
  describe "#select_query?" do
    it "is true for a select" do
      expect(described_class.new("SELECT * FROM widgets", 1.0)).to be_select_query
    end

    it "is false for a write" do
      expect(described_class.new("UPDATE widgets SET name = 'x'", 1.0)).not_to be_select_query
    end

    it "is false when SELECT only appears on a later line" do
      query = "INSERT INTO widgets (name)\nSELECT name FROM widgets"

      expect(described_class.new(query, 1.0)).not_to be_select_query
    end
  end

  describe "#warnings" do
    it "reports a column with no index" do
      explainer = described_class.new("SELECT * FROM widgets WHERE name = 'x'", 1.0)

      expect(explainer.warnings).to eq("widgets" => ["No possible keys"])
      expect(explainer).to be_warnings
    end

    it "reports a sort that cannot use an index" do
      explainer = described_class.new("SELECT * FROM widgets ORDER BY name", 1.0)

      expect(explainer.warnings.fetch("widgets")).to include("Using filesort")
    end

    it "is silent when the primary key is used" do
      explainer = described_class.new("SELECT * FROM widgets WHERE id = 1", 1.0)

      expect(explainer.warnings).to be_empty
      expect(explainer).not_to be_warnings
    end

    it "is silent when a secondary index is used" do
      explainer = described_class.new("SELECT * FROM widgets WHERE code = 'x'", 1.0)

      expect(explainer.warnings).to be_empty
    end

    it "does not treat routine Extra values as warnings" do
      explainer = described_class.new("SELECT code FROM widgets WHERE code = 'x'", 1.0)

      expect(explainer.warnings).to be_empty
    end
  end
end
