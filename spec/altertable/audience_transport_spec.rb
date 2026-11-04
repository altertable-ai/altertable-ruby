# frozen_string_literal: true

require "spec_helper"
require "socket"
require "timeout"

RSpec.describe "Audience HTTP delivery" do
  # Exercise real serialization and all supported transports against a local HTTP sink.
  def with_http_sink(count)
    server = TCPServer.new("127.0.0.1", 0)
    requests = []
    worker = Thread.new do
      count.times do
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
          socket.write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 11\r\nConnection: close\r\n\r\n{\"ok\":true}")
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
    with_http_sink(1) do |base_url, requests|
      client = Altertable::Client.new("test-key", adapter: :httpx, base_url: base_url)
      expect(client.track("Product", "user")).to eq("ok" => true)
      expect(requests.first[:body]).to include("distinct_id" => "user", "environment" => "production")
      expect(requests.first[:body]).not_to have_key("mode")
    end
  end

  [:faraday, :httpx, :net_http].each do |adapter|
    it "sends restricted scalar, hash, and batch requests over #{adapter}" do
      with_http_sink(3) do |base_url, requests|
        client = Altertable::Client.new("test-key", mode: :audience, adapter: adapter, base_url: base_url, proxy: false)
        properties = { "$url" => "https://user:pass@site.example/docs?token=secret#hash",
                       "$referer" => "https://search.example/private?token=secret", "$viewport" => "123x456" }
        expect(client.track("Scalar", "ignored", anonymous_id: "anon", properties: properties)).to eq("ok" => true)
        expect(client.track({ event: "Hash", device_id: "device", properties: properties })).to eq("ok" => true)
        expect(client.track([{ "event" => "Batch", "distinct_id" => "user", "properties" => properties }])).to eq("ok" => true)
        requests.each do |request|
          expect(request[:line]).to start_with("POST /track ")
          expect(request[:headers]).to include("x-api-key" => "test-key", "content-type" => "application/json")
          expect(request[:headers].keys).not_to include("cookie", "referer", "forwarded", "x-forwarded-for")
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
end
