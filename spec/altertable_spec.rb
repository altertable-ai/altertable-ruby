# frozen_string_literal: true

require "altertable"
require "json"

RSpec.describe Altertable do
  let(:api_key) { "pk_test_123" }
  let(:base_url) { ENV["ALTERTABLE_MOCK_URL"] || "http://localhost:15000" }

  before do
    Altertable.init(api_key, base_url: base_url, request_timeout: 30, on_error: ->(e) { puts "DEBUG ERROR: #{e.class} - #{e.message}" }, request_timeout: 30)
  end

  describe ".track" do
    it "sends a track request" do
      response = Altertable.track("test_event", "user_123", { foo: "bar" })
      expect(response).to be_a(Hash)
    end
  end

  describe ".identify" do
    it "sends an identify request" do
      response = Altertable.identify("user_123", { email: "test@example.com" })
      expect(response).to be_a(Hash)
    end

    it "raises error for reserved user ids" do
      expect { Altertable.identify("anonymous") }.to raise_error(ArgumentError)
      expect { Altertable.identify("null") }.to raise_error(ArgumentError)
    end
  end

  describe ".alias" do
    it "sends an alias request" do
      response = Altertable.alias("user_123", "anon_123")
      expect(response).to be_a(Hash)
    end
  end
end
