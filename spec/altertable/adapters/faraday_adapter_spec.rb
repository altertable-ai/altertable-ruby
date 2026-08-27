# frozen_string_literal: true

require "spec_helper"

RSpec.describe Altertable::Adapters::FaradayAdapter do
  let(:base_url) { "https://api.test.local" }
  let(:timeout) { 5 }

  describe "proxy configuration" do
    it "leaves Faraday's own env-based auto-detection in place by default" do
      adapter = described_class.new(base_url: base_url, timeout: timeout)
      conn = adapter.instance_variable_get(:@conn)
      expect(conn.instance_variable_get(:@manual_proxy)).to be false
    end

    it "disables Faraday's env-based auto-detection when proxy: false is given" do
      adapter = described_class.new(base_url: base_url, timeout: timeout, proxy: false)
      conn = adapter.instance_variable_get(:@conn)
      expect(conn.instance_variable_get(:@manual_proxy)).to be true
    end

    it "has no proxy configured when proxy: false is given" do
      adapter = described_class.new(base_url: base_url, timeout: timeout, proxy: false)
      conn = adapter.instance_variable_get(:@conn)
      expect(conn.proxy).to be_nil
    end

    it "uses an explicit proxy when a URI string is given" do
      adapter = described_class.new(base_url: base_url, timeout: timeout, proxy: "http://proxy.local:8080")
      conn = adapter.instance_variable_get(:@conn)
      expect(conn.proxy.uri.host).to eq("proxy.local")
    end
  end
end
