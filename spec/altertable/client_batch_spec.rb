# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe Altertable::Client do
  let(:api_key) { "test_pk_abc123" }
  let(:adapter) { RecordingAdapter.new }
  let(:client) do
    described_class.new(api_key, environment: "production", release: "1.2.3").tap do |c|
      c.instance_variable_set(:@adapter, adapter)
    end
  end

  class RecordingAdapter
    attr_reader :calls

    def initialize(responses: nil)
      @calls = []
      @responses = responses
    end

    def post(path, body: nil, params: {})
      @calls << { path: path, body: JSON.parse(body), params: params }
      response = if @responses
                   @responses.shift || { "ok" => true }
                 else
                   { "ok" => true, "task_id" => "task-1" }
                 end
      Altertable::Adapters::Response.new(200, JSON.generate(response), {})
    end
  end

  describe "#track" do
    it "posts a single event from positional arguments" do
      client.track("signup", "u1", properties: { plan: "pro" }, timestamp: "2025-06-15T14:30:00.000Z")

      expect(adapter.calls.size).to eq(1)
      expect(adapter.calls.first[:path]).to eq("/track")
      payload = adapter.calls.first[:body]
      expect(payload).to include(
        "event" => "signup",
        "distinct_id" => "u1",
        "environment" => "production",
        "timestamp" => "2025-06-15T14:30:00.000Z"
      )
      expect(payload["properties"]).to include("plan" => "pro", "$lib" => "altertable-ruby")
    end

    it "posts a single event from a payload hash" do
      client.track({
        event: "signup",
        distinct_id: "u1",
        properties: { plan: "pro" },
        timestamp: "2025-06-15T14:30:00.000Z"
      })

      payload = adapter.calls.first[:body]
      expect(payload).to be_a(Hash)
      expect(payload).to include("event" => "signup", "distinct_id" => "u1")
      expect(payload["properties"]).to include("plan" => "pro", "$release" => "1.2.3")
    end

    it "posts an array of track payloads in one request" do
      client.track([
        { event: "signup", distinct_id: "u1", properties: { plan: "pro" }, timestamp: "2025-06-15T14:30:00.000Z" },
        { event: "login", distinct_id: "u2", timestamp: "2025-06-15T14:31:00.000Z", anonymous_id: "anon-1" }
      ])

      expect(adapter.calls.size).to eq(1)
      expect(adapter.calls.first[:path]).to eq("/track")
      payloads = adapter.calls.first[:body]
      expect(payloads).to be_an(Array)
      expect(payloads.size).to eq(2)
      expect(payloads[0]).to include(
        "event" => "signup",
        "distinct_id" => "u1",
        "environment" => "production",
        "timestamp" => "2025-06-15T14:30:00.000Z"
      )
      expect(payloads[0]["properties"]).to include("plan" => "pro", "$lib" => "altertable-ruby", "$lib_version" => Altertable::VERSION, "$release" => "1.2.3")
      expect(payloads[1]).to include(
        "event" => "login",
        "distinct_id" => "u2",
        "anonymous_id" => "anon-1",
        "timestamp" => "2025-06-15T14:31:00.000Z"
      )
    end

    it "defaults omitted timestamps to ISO 8601" do
      client.track([{ event: "signup", distinct_id: "u1" }])

      timestamp = adapter.calls.first[:body].first["timestamp"]
      expect { Time.iso8601(timestamp) }.not_to raise_error
    end

    it "returns the parsed response" do
      response = client.track([{ event: "signup", distinct_id: "u1" }])
      expect(response).to include("ok" => true)
    end

    it "raises ArgumentError for an empty list" do
      expect { client.track([]) }.to raise_error(ArgumentError, /empty/)
      expect(adapter.calls).to be_empty
    end

    it "raises ArgumentError when event is missing from a payload" do
      expect { client.track([{ distinct_id: "u1" }]) }.to raise_error(ArgumentError, /event/)
    end
  end

  describe "#identify" do
    it "posts a single identify from a payload hash" do
      client.identify({
        user_id: "u1",
        traits: { email: "a@example.com" },
        timestamp: "2025-06-15T14:30:00.000Z"
      })

      payload = adapter.calls.first[:body]
      expect(payload).to be_a(Hash)
      expect(payload).to include("distinct_id" => "u1", "timestamp" => "2025-06-15T14:30:00.000Z")
      expect(payload["traits"]).to include("email" => "a@example.com")
    end

    it "posts an array of identify payloads" do
      client.identify([
        { user_id: "u1", traits: { email: "a@example.com" }, timestamp: "2025-06-15T14:30:00.000Z" },
        { user_id: "u2", device_id: "device-1", timestamp: "2025-06-15T14:31:00.000Z" }
      ])

      expect(adapter.calls.size).to eq(1)
      expect(adapter.calls.first[:path]).to eq("/identify")
      payloads = adapter.calls.first[:body]
      expect(payloads[0]).to include(
        "distinct_id" => "u1",
        "environment" => "production",
        "timestamp" => "2025-06-15T14:30:00.000Z"
      )
      expect(payloads[0]["traits"]).to include("email" => "a@example.com")
      expect(payloads[1]).to include("distinct_id" => "u2", "device_id" => "device-1")
    end

    it "raises ArgumentError for an empty list" do
      expect { client.identify([]) }.to raise_error(ArgumentError, /empty/)
    end
  end

  describe "#alias" do
    it "posts a single alias from a payload hash" do
      client.alias({ distinct_id: "anon-1", new_user_id: "u1", timestamp: "2025-06-15T14:30:00.000Z" })

      payload = adapter.calls.first[:body]
      expect(payload).to be_a(Hash)
      expect(payload).to include(
        "distinct_id" => "anon-1",
        "new_user_id" => "u1",
        "timestamp" => "2025-06-15T14:30:00.000Z"
      )
    end

    it "posts an array of alias payloads" do
      client.alias([
        { distinct_id: "anon-1", new_user_id: "u1", timestamp: "2025-06-15T14:30:00.000Z" },
        { distinct_id: "anon-2", new_user_id: "u2" }
      ])

      expect(adapter.calls.size).to eq(1)
      expect(adapter.calls.first[:path]).to eq("/alias")
      payloads = adapter.calls.first[:body]
      expect(payloads[0]).to include(
        "distinct_id" => "anon-1",
        "new_user_id" => "u1",
        "environment" => "production",
        "timestamp" => "2025-06-15T14:30:00.000Z"
      )
      expect(payloads[1]).to include("distinct_id" => "anon-2", "new_user_id" => "u2")
    end

    it "raises ArgumentError for an empty list" do
      expect { client.alias([]) }.to raise_error(ArgumentError, /empty/)
    end
  end
end
