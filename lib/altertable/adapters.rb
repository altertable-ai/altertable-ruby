module Altertable
  module Adapters
    Response = Struct.new(:status, :body, :headers)

    class Base
      def initialize(base_url:, timeout:, headers: {})
        @base_url = base_url
        @timeout = timeout
        @headers = headers
      end

      def post(path, body: nil, params: {}, &block)
        raise NotImplementedError
      end
    end

    class FaradayAdapter < Base
      def initialize(base_url:, timeout:, headers: {})
        super
        require "faraday"
        
        @conn = Faraday.new(url: @base_url) do |f|
          @headers.each { |k, v| f.headers[k] = v }
          f.options.timeout = @timeout
          f.adapter Faraday.default_adapter
        end
      end

      def post(path, body: nil, params: {})
        resp = @conn.post(path) do |req|
          req.params = params
          req.body = body
        end
        wrap_response(resp)
      rescue Faraday::ConnectionFailed => e
        raise Altertable::NetworkError.new(e.message, e)
      rescue Faraday::TimeoutError => e
        raise Altertable::NetworkError.new("Timeout: #{e.message}", e)
      end

      private

      def wrap_response(resp)
        Response.new(resp.status, resp.body, resp.headers)
      end
    end

    class HttpxAdapter < Base
      def initialize(base_url:, timeout:, headers: {})
        super
        require "httpx"
        @client = HTTPX.plugin(:retries).with(
          timeout: { operation_timeout: @timeout },
          headers: @headers,
          base_url: @base_url
        )
      end

      def post(path, body: nil, params: {})
        resp = @client.post(path, body: body, params: params)
        wrap_response(resp)
      rescue HTTPX::Error => e
        raise Altertable::NetworkError.new(e.message, e)
      end

      private

      def wrap_response(resp)
        if resp.is_a?(HTTPX::ErrorResponse)
          raise Altertable::NetworkError.new(resp.error.message, resp.error)
        end
        Response.new(resp.status, resp.to_s, resp.headers)
      end
    end

    class NetHttpAdapter < Base
      def initialize(base_url:, timeout:, headers: {})
        super
        require "net/http"
        require "uri"
        @uri = URI.parse(@base_url)
      end

      def post(path, body: nil, params: {})
        uri = URI.join(@uri, path)
        uri.query = URI.encode_www_form(params) unless params.empty?

        req = Net::HTTP::Post.new(uri)
        @headers.each { |k, v| req[k] = v }
        req.body = body if body

        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: @timeout, read_timeout: @timeout) do |http|
          resp = http.request(req)
          Response.new(resp.code.to_i, resp.body, resp.to_hash)
        end
      rescue SocketError, Net::OpenTimeout, Net::ReadTimeout => e
        raise Altertable::NetworkError.new("Timeout: #{e.message}", e)
      rescue StandardError => e
        raise Altertable::NetworkError.new(e.message, e)
      end
    end
  end
end
