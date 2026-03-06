# frozen_string_literal: true

require "altertable"
require "testcontainers"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before(:suite) do
    @container = Testcontainers::DockerContainer.new("altertable/mock-server:v0.1.0").with_env("PORT", "15000").with_exposed_ports(15000).with_wait_for(Testcontainers::Wait::Http.new(path: "/health").with_port(15000))
                                                .with_exposed_ports(15001)
    @container.start
    
    # Wait for the server to be ready
    attempts = 0
    begin
      Net::HTTP.get(URI("http://#{@container.host}:#{@container.mapped_port(15000)}/health"))
    rescue StandardError
      attempts += 1
      if attempts < 10
        sleep 1
        retry
      end
    end

    ENV["ALTERTABLE_MOCK_URL"] = "http://#{@container.host}:#{@container.mapped_port(15000)}"
  end

  config.after(:suite) do
    @container&.stop
    @container&.remove
  end
end
