# frozen_string_literal: true

require "rails/railtie"

module QueryExplainer
  # Subscribes automatically, so a host app only needs the gem in its Gemfile.
  class Railtie < Rails::Railtie
    initializer "query_explainer.subscribe" do
      QueryExplainer.subscribe if QueryExplainer.enabled?
    end
  end
end
