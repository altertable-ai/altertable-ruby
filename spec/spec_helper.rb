# frozen_string_literal: true

require "altertable"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before(:suite) do
    # For now, we skip testcontainers in CI and use a public mock server if available,
    # or just stub the network calls for the time being to unblock CI.
    # Long term fix involves making the mock-server image public or configuring GHCR secrets.
    ENV["ALTERTABLE_MOCK_URL"] ||= "http://127.0.0.1:15001"
  end
end
