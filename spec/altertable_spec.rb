# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe Altertable do
  let(:api_key) { "pk_test_123" }
  let(:base_url) { "http://127.0.0.1:15001" }

  before do
    Altertable.init(api_key, base_url: base_url)
    
    stub_request(:post, "#{base_url}/track").to_return(status: 200, body: '{"status":"success"}')
    stub_request(:post, "#{base_url}/identify").to_return(status: 200, body: '{"status":"success"}')
    stub_request(:post, "#{base_url}/alias").to_return(status: 200, body: '{"status":"success"}')
  end

  it "has a version number" do
    expect(Altertable::VERSION).not_to be_nil
  end

  describe ".track" do
    it "sends a track request" do
      response = Altertable.track(
        "test_event",
        "user_123",
        { key: "value" }
      )
      expect(response).to be_truthy
      expect(a_request(:post, "#{base_url}/track")).to have_been_made
    end
  end

  describe ".identify" do
    it "sends an identify request" do
      response = Altertable.identify(
        "user_123",
        { email: "test@example.com" }
      )
      expect(response).to be_truthy
      expect(a_request(:post, "#{base_url}/identify")).to have_been_made
    end
  end

  describe ".alias" do
    it "sends an alias request" do
      response = Altertable.alias(
        "new_id",
        "old_id"
      )
      expect(response).to be_truthy
      expect(a_request(:post, "#{base_url}/alias")).to have_been_made
    end
  end
end
