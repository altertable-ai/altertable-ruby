# frozen_string_literal: true

require "spec_helper"

RSpec.describe Altertable do
  let(:api_key) { "test_api_key" }
  let(:base_url) { ENV["ALTERTABLE_MOCK_URL"] || "http://127.0.0.1:15001" }

  before do
    Altertable.configure do |config|
      config.api_key = api_key
      config.base_url = base_url
      config.request_timeout = 30
      config.on_error = ->(e) { puts "DEBUG ERROR: #{e.class} - #{e.message}" }
    end
  end

  it "has a version number" do
    expect(Altertable::VERSION).not_to be_nil
  end

  describe ".track" do
    it "sends a track request" do
      response = Altertable.track(
        event: "test_event",
        user_id: "user_123",
        properties: { key: "value" }
      )
      expect(response).to be_truthy
    end
  end

  describe ".identify" do
    it "sends an identify request" do
      response = Altertable.identify(
        user_id: "user_123",
        traits: { email: "test@example.com" }
      )
      expect(response).to be_truthy
    end
  end

  describe ".alias" do
    it "sends an alias request" do
      response = Altertable.alias(
        previous_id: "old_id",
        user_id: "new_id"
      )
      expect(response).to be_truthy
    end
  end
end
