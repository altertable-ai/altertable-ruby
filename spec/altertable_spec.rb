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
        properties: { key: "value" }
      )
      expect(response).to include("ok" => true)
    end
  end

  describe ".identify" do
    it "sends an identify request" do
      response = Altertable.identify(
        "user_123",
        traits: { email: "test@example.com" }
      )
      expect(response).to include("ok" => true)
    end
  end

  describe ".alias" do
    it "sends an alias request" do
      response = Altertable.alias("old_id", "new_id")
      expect(response).to include("ok" => true)
    end
  end

  describe ".track with a payload hash" do
    it "sends a track request" do
      response = Altertable.track({
        event: "test_event",
        distinct_id: "user_123",
        properties: { key: "value" }
      })
      expect(response).to include("ok" => true)
    end
  end

  describe ".track with a payload array" do
    it "sends a batch of track events" do
      response = Altertable.track([
        { event: "event_a", distinct_id: "user_1" },
        { event: "event_b", distinct_id: "user_2", properties: { key: "value" } }
      ])
      expect(response).to include("ok" => true)
    end
  end

  describe ".identify with a payload array" do
    it "sends a batch of identify requests" do
      response = Altertable.identify([
        { user_id: "user_1", traits: { email: "one@example.com" } },
        { user_id: "user_2", traits: { email: "two@example.com" } }
      ])
      expect(response).to include("ok" => true)
    end
  end

  describe ".alias with a payload array" do
    it "sends a batch of alias requests" do
      response = Altertable.alias([
        { distinct_id: "old_1", new_user_id: "new_1" },
        { distinct_id: "old_2", new_user_id: "new_2" }
      ])
      expect(response).to include("ok" => true)
    end
  end

  describe "authentication" do
    context "with wrong API key" do
      before do
        Altertable.init("wrong_api_key", base_url: MOCK_BASE_URL)
      end

      it "raises an ApiError when tracking" do
        expect {
          Altertable.track("test_event", "user_123", properties: { key: "value" })
        }.to raise_error(Altertable::ApiError)
      end
    end
  end
end
