# frozen_string_literal: true

require "spec_helper"

RSpec.describe Altertable::Client do
  describe "#initialize adapter selection" do
    let(:api_key) { "test_api_key" }
    let(:base_url) { "https://api.test.local" }

    context "when adapter is explicitly provided" do
      it "uses FaradayAdapter when :faraday is requested" do
        client = described_class.new(api_key, base_url: base_url, adapter: :faraday)
        adapter = client.instance_variable_get(:@adapter)
        expect(adapter).to be_a(Altertable::Adapters::FaradayAdapter)
      end

      it "uses HttpxAdapter when :httpx is requested" do
        client = described_class.new(api_key, base_url: base_url, adapter: :httpx)
        adapter = client.instance_variable_get(:@adapter)
        expect(adapter).to be_a(Altertable::Adapters::HttpxAdapter)
      end

      it "uses NetHttpAdapter when :net_http is requested" do
        client = described_class.new(api_key, base_url: base_url, adapter: :net_http)
        adapter = client.instance_variable_get(:@adapter)
        expect(adapter).to be_a(Altertable::Adapters::NetHttpAdapter)
      end
    end
  end
end
