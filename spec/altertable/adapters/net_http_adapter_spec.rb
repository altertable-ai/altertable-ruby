# frozen_string_literal: true

require "spec_helper"

RSpec.describe Altertable::Adapters::NetHttpAdapter do
  let(:base_url) { "https://api.test.local" }
  let(:timeout) { 5 }

  describe "proxy configuration" do
    it "leaves Net::HTTP's own env-based auto-detection in place by default" do
      adapter = described_class.new(base_url: base_url, timeout: timeout)
      expect(adapter.send(:proxy_start_args)).to eq([])
    end

    it "disables proxying when proxy: false is given" do
      adapter = described_class.new(base_url: base_url, timeout: timeout, proxy: false)
      expect(adapter.send(:proxy_start_args)).to eq([nil])
    end

    it "uses an explicit proxy when a URI string is given" do
      adapter = described_class.new(base_url: base_url, timeout: timeout, proxy: "http://user:pass@proxy.local:8080")
      expect(adapter.send(:proxy_start_args)).to eq(["proxy.local", 8080, "user", "pass"])
    end
  end
end
