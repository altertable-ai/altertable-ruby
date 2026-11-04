# frozen_string_literal: true

require "spec_helper"

RSpec.describe Altertable::Client, "audience mode" do
  let(:adapter) { instance_double(Altertable::Adapters::NetHttpAdapter) }
  let(:calls) { [] }
  let(:client) { build_client(mode: :audience) }

  def build_client(**options)
    described_class.new("key", { adapter: :net_http }.merge(options)).tap do |instance|
      instance.instance_variable_set(:@adapter, adapter)
    end
  end

  before do
    allow(adapter).to receive(:post) do |path, body:|
      calls << { path: path, body: JSON.parse(body) }
      Altertable::Adapters::Response.new(200, '{"ok":true}', {})
    end
  end

  def expect_audience(payload)
    expect(payload.keys).to contain_exactly("mode", "event", "timestamp", "properties")
    expect(payload["mode"]).to eq("audience")
    expect { Time.iso8601(payload["timestamp"]) }.not_to raise_error
    expect(payload["properties"]).to include("$lib" => "altertable-ruby", "$lib_version" => Altertable::VERSION)
    expect(payload["properties"]).not_to have_key("$viewport")
  end

  it "omits all identity fields and environment from scalar events" do
    client.track("Opened", "ignored", anonymous_id: "anon", device_id: "device", session_id: "session", environment: "private", mode: "product")
    expect_audience(calls.last[:body])
    expect(calls.last[:path]).to eq("/track")
  end

  it "accepts events without distinct IDs in scalar, hash, and batch forms" do
    expect(client.track("Scalar")).to eq("ok" => true)
    client.track({ event: "Hash" })
    client.track([{ event: "Batch" }, { "event" => "String keys" }])
    payloads = calls.flat_map { |call| call[:body].is_a?(Array) ? call[:body] : [call[:body]] }
    expect(payloads.map { |payload| payload["event"] }).to eq(["Scalar", "Hash", "Batch", "String keys"])
    payloads.each { |payload| expect_audience(payload) }
  end

  it "enforces client mode on hash and batch overrides" do
    item = { "event" => "Opened", "mode" => "product", "distinct_id" => "user", "anonymous_id" => "anon",
             "device_id" => "device", "session_id" => "session", "environment" => "private" }.freeze
    client.track(item, mode: :product, distinct_id: "override")
    client.track([item], mode: :product, distinct_id: "override")
    expect_audience(calls.first[:body])
    expect_audience(calls.last[:body].first)
  end

  it "sanitizes symbol and string built-ins after merging caller properties without mutating them" do
    properties = { :"$url" => "https://user:password@SITE.example:443/docs?token=secret#hash",
                   "$referer" => "http://user:password@search.example:8080/private?token=secret",
                   :"$viewport" => "1234x987", "$viewport" => "another", section: "intro" }.freeze
    client.track({ event: "Opened", properties: properties }, timestamp: "2026-11-04T10:00:00.000Z")
    payload = calls.last[:body]
    expect(payload["timestamp"]).to eq("2026-11-04T10:00:00.000Z")
    expect(payload["properties"]).to include("$url" => "https://site.example/docs", "$referer" => "http://search.example:8080", "section" => "intro")
    expect(payload["properties"]).not_to have_key("$viewport")
    expect(properties[:"$url"]).to include("secret")
  end

  [nil, 123, "not a URL?token=secret", "javascript:secret", "/relative?token=secret", "https://", "https://host:bad/path", "https://host:99999/path"].each do |url|
    it "discards unsupported URL and referrer values: #{url.inspect}" do
      client.track("Opened", properties: { "$url" => url, "$referer" => url })
      expect(calls.last[:body]["properties"]).to include("$url" => nil, "$referer" => nil)
    end
  end

  it "preserves paths, IPv6 hosts, and non-default ports without extracting query parameters" do
    client.track("Opened", properties: { "$url" => "http://[::1]:8080/a%20b?email=private#secret", "$referer" => "https://search.example" })
    expect(calls.last[:body]["properties"]).to include("$url" => "http://[::1]:8080/a%20b", "$referer" => "https://search.example")
    expect(calls.last[:body]["properties"]).not_to have_key("email")
  end

  it "retains caller properties and release metadata without claiming to scrub custom PII" do
    build_client(mode: :audience, release: "1.2.3").track("Opened", properties: { email: "caller@example.com" })
    expect(calls.last[:body]["properties"]).to include("$release" => "1.2.3", "email" => "caller@example.com", "$url" => nil, "$referer" => nil)
  end

  it "ignores scalar, hash, batch, and invalid identity calls before validation" do
    ["user", {}, [], [nil], nil].each do |identity|
      expect(client.identify(identity)).to be_nil
      expect(client.alias(identity)).to be_nil
    end
    expect(calls).to be_empty
    client.track("Still collecting")
    expect_audience(calls.last[:body])
  end

  it "warns about ignored identity calls when debug logging is enabled" do
    debug_client = build_client(mode: :audience, debug: true)
    expect { debug_client.identify("user") }.to output(/ignored in audience mode/).to_stderr
    expect { debug_client.alias("old", "new") }.to output(/ignored in audience mode/).to_stderr
    expect { client.identify("user") }.not_to output.to_stderr
  end

  it "validates events and whole batches without sending partial batches" do
    expect { client.track({}) }.to raise_error(ArgumentError, /event/)
    expect { client.track([{ event: "Valid" }, {}]) }.to raise_error(ArgumentError, /event/)
    expect { client.track([]) }.to raise_error(ArgumentError, /empty/)
    expect { client.track([nil]) }.to raise_error(ArgumentError, /Hash/)
    expect(calls).to be_empty
  end

  [:product, "product"].each do |mode|
    it "preserves product payloads and identity validation with mode #{mode.inspect}" do
      product = build_client(mode: mode, environment: "staging")
      product.track("Opened", "user", anonymous_id: "anon", device_id: "device", mode: :audience,
                    properties: { "$url" => "https://site.example/?private=yes", "$viewport" => "100x100" })
      expect(calls.last[:body]).to include("distinct_id" => "user", "anonymous_id" => "anon", "device_id" => "device", "environment" => "staging")
      expect(calls.last[:body]).not_to have_key("mode")
      expect(calls.last[:body]["properties"]).to include("$url" => "https://site.example/?private=yes", "$viewport" => "100x100")
      expect { product.track({ event: "No ID" }) }.to raise_error(ArgumentError, /distinct_id/)
      expect { product.track([{ event: "No ID" }]) }.to raise_error(ArgumentError, /distinct_id/)
      product.identify("user")
      expect(calls.last[:path]).to eq("/identify")
      product.alias("old", "new")
      expect(calls.last[:path]).to eq("/alias")
    end
  end

  it "defaults to product mode" do
    build_client.track("Opened", "user")
    expect(calls.last[:body]).to include("distinct_id" => "user", "environment" => "production")
    expect(calls.last[:body]).not_to have_key("mode")
  end

  it "captures the mode value at construction" do
    mode = +"audience"
    instance = build_client(mode: mode)
    mode.replace("product")
    instance.track("Opened")
    expect_audience(calls.last[:body])
  end

  it "switches global clients through init and preserves an active client after invalid initialization" do
    original = Altertable.instance_variable_get(:@client)
    begin
      product = Altertable.init("key", adapter: :net_http)
      product.instance_variable_set(:@adapter, adapter)
      Altertable.track("Product", "user")
      audience = Altertable.init("key", mode: "audience", adapter: :net_http)
      audience.instance_variable_set(:@adapter, adapter)
      expect { Altertable.init("key", mode: :invalid) }.to raise_error(Altertable::ConfigurationError, /tracking mode/)
      expect(Altertable.client).to equal(audience)
      Altertable.identify("ignored")
      Altertable.track("Audience")
      expect(calls.map { |call| call[:body]["event"] }).to eq(["Product", "Audience"])
      expect_audience(calls.last[:body])
      product.track("Independent", "user")
      expect(calls.last[:body]).not_to have_key("mode")
      replacement = Altertable.init("key", mode: :product, adapter: :net_http)
      replacement.instance_variable_set(:@adapter, adapter)
      Altertable.track("Product again", "new-user")
      expect(calls.last[:body]).to include("distinct_id" => "new-user")
      expect(calls.last[:body]).not_to have_key("mode")
    ensure
      Altertable.instance_variable_set(:@client, original)
    end
  end

  [nil, false, :anonymous, "", {}].each do |mode|
    it "rejects invalid mode #{mode.inspect} before constructing a transport" do
      expect(Altertable::Adapters::NetHttpAdapter).not_to receive(:new)
      expect { build_client(mode: mode) }.to raise_error(Altertable::ConfigurationError, /tracking mode/)
    end
  end

  it "keeps audience policy on caller retries after a failed batch" do
    on_error = spy("on_error")
    instance = build_client(mode: :audience, on_error: on_error)
    allow(adapter).to receive(:post) do |path, body:|
      calls << { path: path, body: JSON.parse(body) }
      Altertable::Adapters::Response.new(calls.length == 1 ? 503 : 200, '{}', {})
    end
    items = [{ event: "Retry", distinct_id: "ignored", properties: { "$url" => "https://site.example/?secret=yes" } }]
    expect { instance.track(items) }.to raise_error(Altertable::ApiError)
    expect(on_error).to have_received(:call).with(an_instance_of(Altertable::ApiError))
    instance.track(items)
    expect(calls.length).to eq(2)
    calls.each { |call| expect_audience(call[:body].first) }
    expect(calls.last[:body].first["properties"]["$url"]).to eq("https://site.example/")
  end

  it "reports delivery failures and does not replay failed events into another client" do
    callback = spy("on_error")
    failing = build_client(mode: :product, on_error: callback)
    allow(adapter).to receive(:post).and_raise(Altertable::NetworkError, "offline")
    expect { failing.track("Failed product", "user") }.to raise_error(Altertable::NetworkError)
    expect(callback).to have_received(:call).with(an_instance_of(Altertable::NetworkError))
    allow(adapter).to receive(:post) do |path, body:|
      calls << { path: path, body: JSON.parse(body) }
      Altertable::Adapters::Response.new(200, '{}', {})
    end
    client.track("Fresh audience")
    expect(calls.length).to eq(1)
    expect_audience(calls.last[:body])
  end
end
