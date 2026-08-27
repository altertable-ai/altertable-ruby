# frozen_string_literal: true

require "spec_helper"

RSpec.describe Altertable::Adapters::HttpxAdapter do
  let(:base_url) { "https://api.test.local" }
  let(:timeout) { 5 }

  describe "proxy configuration" do
    # Introspects the httpx client's actual proxy option rather than the class name:
    # httpx's plugin system only gives its dynamically generated classes readable
    # names on Ruby >= 3.4 (via Class#set_temporary_name), so `client.class.to_s`
    # is anonymous (e.g. "#<Class:0x...>") on older Rubies and can't be asserted on.
    def proxy_option(adapter)
      options = adapter.instance_variable_get(:@client).instance_variable_get(:@options)
      options.proxy if options.respond_to?(:proxy)
    end

    it "does not proxy by default (httpx never auto-detects env proxies)" do
      adapter = described_class.new(base_url: base_url, timeout: timeout)
      expect(proxy_option(adapter)).to be_nil
    end

    it "does not proxy when proxy: false is given" do
      adapter = described_class.new(base_url: base_url, timeout: timeout, proxy: false)
      expect(proxy_option(adapter)).to be_nil
    end

    it "uses an explicit proxy when a URI string is given" do
      adapter = described_class.new(base_url: base_url, timeout: timeout, proxy: "http://proxy.local:8080")
      expect(proxy_option(adapter).uri.to_s).to eq("http://proxy.local:8080")
    end
  end
end
