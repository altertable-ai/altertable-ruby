# frozen_string_literal: true

require "spec_helper"
require "socket"
require "timeout"

RSpec.describe "Audience HTTP delivery" do
  # Exercise real serialization and all supported transports against a local HTTP sink.
  def with_http_sink(responses)
    server = TCPServer.new("127.0.0.1", 0)
    requests = []
    worker = Thread.new do
      responses.each do |response|
        socket = Timeout.timeout(10) { server.accept }
        begin
          request_line = socket.gets
          headers = {}
          while (line = socket.gets) && line != "\r\n"
            key, value = line.split(":", 2)
            headers[key.downcase] = value.strip
          end
          body = socket.read(Integer(headers.fetch("content-length")))
          requests << { line: request_line, headers: headers, body: JSON.parse(body) }
          socket.write(response)
        ensure
          socket.close
        end
      end
    end
    yield "http://127.0.0.1:#{server.addr[1]}", requests
    expect(worker.join(10)).not_to be_nil
    worker.value
  ensure
    worker&.kill
    worker&.join
    server&.close
  end

  it "preserves identified product delivery through HTTPX" do
    with_http_sink([ok_response]) do |base_url, requests|
      client = Altertable::Client.new("test-key", adapter: :httpx, base_url: base_url)
      expect(client.track("Product", "user")).to eq("ok" => true)
      expect(requests.first[:body]).to include("distinct_id" => "user", "environment" => "production")
      expect(requests.first[:body]).not_to have_key("mode")
    end
  end

  [:faraday, :httpx, :net_http].each do |adapter|
    it "sends restricted scalar, hash, and batch requests over #{adapter}" do
      with_http_sink(Array.new(3, ok_response)) do |base_url, requests|
        client = Altertable::Client.new("test-key", mode: :audience, adapter: adapter, base_url: base_url, proxy: false)
        properties = { "$url" => "https://user:pass@site.example/docs?token=secret#hash",
                       "$referer" => "https://search.example/private?token=secret", "$viewport" => "123x456" }
        expect(client.track("Scalar", "ignored", anonymous_id: "anon", properties: properties)).to eq("ok" => true)
        expect(client.track({ event: "Hash", device_id: "device", properties: properties })).to eq("ok" => true)
        expect(client.track([{ "event" => "Batch", "distinct_id" => "user", "properties" => properties }])).to eq("ok" => true)
        requests.each do |request|
          expect(request[:line]).to start_with("POST /track ")
          expect(request[:headers]).to include("x-api-key" => "test-key", "content-type" => "application/json")
          expect(request[:headers].keys).not_to include("authorization", "cookie", "referer", "forwarded", "x-forwarded-for")
          payloads = request[:body].is_a?(Array) ? request[:body] : [request[:body]]
          payloads.each do |payload|
            expect(payload.keys).to contain_exactly("mode", "event", "timestamp", "properties")
            expect(payload["mode"]).to eq("audience")
            expect(payload["properties"]).to include("$url" => "https://site.example/docs", "$referer" => "https://search.example")
            expect(payload["properties"]).not_to have_key("$viewport")
          end
        end
      end
    end
  end

  [:faraday, :httpx, :net_http].each do |adapter|
    it "does not persist cookies or follow redirects over #{adapter}" do
      responses = [
        "HTTP/1.1 200 OK\r\nSet-Cookie: visitor=private\r\nContent-Type: application/json\r\nContent-Length: 11\r\nConnection: close\r\n\r\n{\"ok\":true}",
        "HTTP/1.1 302 Found\r\nLocation: /redirected\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
      ]
      with_http_sink(responses) do |base_url, requests|
        client = Altertable::Client.new("test-key", mode: :audience, adapter: adapter, base_url: base_url, proxy: false)
        expect(client.track("First")).to eq("ok" => true)
        expect { client.track("Second") }.to raise_error(Altertable::ApiError, /HTTP Error: 302/)
        expect(requests.length).to eq(2)
        expect(requests.last[:headers]).not_to have_key("cookie")
      end
    end
  end

  it "rejects audience endpoints with embedded credentials before delivery" do
    with_http_sink([]) do |base_url, requests|
      endpoint = base_url.sub("http://", "http://user:password@")
      expect do
        Altertable::Client.new("test-key", mode: :audience, adapter: :faraday, base_url: endpoint, proxy: false)
      end.to raise_error(Altertable::ConfigurationError, /cannot include credentials/)
      expect(requests).to be_empty
    end
  end

  def ok_response
    "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 11\r\nConnection: close\r\n\r\n{\"ok\":true}"
  end
end
