# frozen_string_literal: true

require "altertable"
require "testcontainers"
require "net/http"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before(:suite) do
    @container = Testcontainers::DockerContainer.new("altertable/mock-server:latest").with_env("PORT", "15001").with_exposed_ports(15001)
    @container.start
    
    port = @container.mapped_port(15001)
    host = @container.host
    
    puts "DEBUG: Container host: #{host}"
    puts "DEBUG: Container mapped port: #{port}"
    
    # Wait for the server to be ready
    attempts = 0
    begin
      Net::HTTP.get(URI("http://#{host}:#{port}/health"))
    rescue StandardError => e
      attempts += 1
      if attempts < 20
        puts "DEBUG: Wait attempt #{attempts} failed: #{e.message}. Retrying..."
        sleep 1
        retry
      end
      puts "DEBUG: Failed to reach mock server health endpoint after #{attempts} attempts"
    end

    ENV["ALTERTABLE_MOCK_URL"] = "http://#{host}:#{port}"
    Altertable.configure { |c| c.on_error = ->(e) { puts "DEBUG ERROR: #{e.class} - #{e.message}" } }
  end

  config.after(:suite) do
    @container&.stop
    @container&.remove
  end
end
