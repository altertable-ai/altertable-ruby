# frozen_string_literal: true

require "spec_helper"

RSpec.describe Altertable do
  let(:api_key) { "test_pk_abc123" }
  let(:base_url) { "http://127.0.0.1:15000" }

  before do
    Altertable.init(api_key, base_url: base_url)
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
    end
  end

  describe ".identify" do
    it "sends an identify request" do
      response = Altertable.identify(
        "user_123",
        { email: "test@example.com" }
      )
      expect(response).to be_truthy
    end
  end

  describe ".alias" do
    it "sends an alias request" do
      response = Altertable.alias(
        "new_id",
        "old_id"
      )
      expect(response).to be_truthy
    end
  end
end
