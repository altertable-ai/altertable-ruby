# frozen_string_literal: true

require "spec_helper"
require "socket"
require "timeout"

RSpec.describe "Adapter delivery" do
  # Accepts one request on a loopback socket and records its request line.
  def with_http_sink
    server = TCPServer.new("127.0.0.1", 0)
    worker = Thread.new do
      socket = Timeout.timeout(10) { server.accept }
      begin
        request_line = socket.gets
        headers = {}
        while (line = socket.gets) && line != "\r\n"
          key, value = line.split(":", 2)
          headers[key.downcase] = value.strip
        end
        socket.read(Integer(headers.fetch("content-length", "0")))
        body = '{"ok":true}'
        socket.write("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}")
        request_line
      ensure
        socket.close
      end
    end
    yield "http://127.0.0.1:#{server.addr[1]}"
    worker.value
  ensure
    worker&.kill
    server&.close
  end

  [:faraday, :httpx, :net_http].each do |adapter|
    it "posts track events to the base URL over #{adapter}" do
      request_line = with_http_sink do |base_url|
        client = Altertable::Client.new("test-key", adapter: adapter, base_url: base_url, proxy: false)
        expect(client.track("Signed Up", "user")).to eq("ok" => true)
      end
      expect(request_line).to start_with("POST /track")
    end
  end
end
