# frozen_string_literal: true

require "spec_helper"

MOCK_BASE_URL = "http://localhost:#{ENV.fetch("ALTERTABLE_MOCK_PORT", 15001)}"

RSpec.describe Altertable do
  let(:api_key) { "test_pk_abc123" }

  before do
    Altertable.init(api_key, base_url: MOCK_BASE_URL)
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
      expect(response).to include("ok" => true)
    end
  end

  describe ".identify" do
    it "sends an identify request" do
      response = Altertable.identify(
        "user_123",
        { email: "test@example.com" }
      )
      expect(response).to include("ok" => true)
    end
  end

  describe ".alias" do
    it "raises an error because the endpoint does not exist" do
      expect {
        Altertable.alias("new_id", "old_id")
      }.to raise_error(Altertable::ApiError)
    end
  end

  describe "authentication" do
    context "with wrong API key" do
      before do
        Altertable.init("wrong_api_key", base_url: MOCK_BASE_URL)
      end

      it "raises an ApiError when tracking" do
        expect {
          Altertable.track("test_event", "user_123", { key: "value" })
        }.to raise_error(Altertable::ApiError)
      end
    end
  end
end
