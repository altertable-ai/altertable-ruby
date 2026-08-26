# frozen_string_literal: true

require "spec_helper"

RSpec.describe Altertable::Adapters::HttpxAdapter do
  let(:base_url) { "https://api.test.local" }
  let(:timeout) { 5 }

  describe "proxy configuration" do
    it "does not proxy by default (httpx never auto-detects env proxies)" do
      adapter = described_class.new(base_url: base_url, timeout: timeout)
      client = adapter.instance_variable_get(:@client)
      expect(client.class.to_s).not_to include("Plugins::Proxy")
    end

    it "does not proxy when proxy: false is given" do
      adapter = described_class.new(base_url: base_url, timeout: timeout, proxy: false)
      client = adapter.instance_variable_get(:@client)
      expect(client.class.to_s).not_to include("Plugins::Proxy")
    end

    it "uses an explicit proxy when a URI string is given" do
      adapter = described_class.new(base_url: base_url, timeout: timeout, proxy: "http://proxy.local:8080")
      client = adapter.instance_variable_get(:@client)
      expect(client.class.to_s).to include("Plugins::Proxy")
    end
  end
end
