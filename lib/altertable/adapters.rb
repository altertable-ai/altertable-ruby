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
      # proxy left unset (default) follows Faraday's own env-based auto-detection
      # (HTTP_PROXY/HTTPS_PROXY/NO_PROXY). Pass `false` to disable proxying entirely for
      # fixed, trusted destinations, or a URI string to force a specific proxy.
      def initialize(base_url:, timeout:, headers: {}, proxy: nil)
        super(base_url: base_url, timeout: timeout, headers: headers)
        require "faraday"

        @conn = Faraday.new(url: @base_url) do |f|
          @headers.each { |k, v| f.headers[k] = v }
          f.options.timeout = @timeout
          f.proxy = proxy unless proxy.nil?
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
      # This adapter never auto-detects HTTP_PROXY/HTTPS_PROXY (httpx requires the :proxy
      # plugin to be loaded explicitly). `proxy: false` and the default (unset) are
      # therefore equivalent; pass a URI string to force a specific proxy.
      def initialize(base_url:, timeout:, headers: {}, proxy: nil)
        super(base_url: base_url, timeout: timeout, headers: headers)
        require "httpx"
        client = proxy ? HTTPX.plugin(:proxy).plugin(:retries).with(proxy: { uri: proxy }) : HTTPX.plugin(:retries)
        @client = client.with(
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
      # proxy left unset (default) follows Net::HTTP's own env-based auto-detection
      # (HTTP_PROXY/HTTPS_PROXY/NO_PROXY). Pass `false` to disable proxying entirely for
      # fixed, trusted destinations, or a URI string to force a specific proxy.
      def initialize(base_url:, timeout:, headers: {}, proxy: nil)
        super(base_url: base_url, timeout: timeout, headers: headers)
        require "net/http"
        require "uri"
        @uri = URI.parse(@base_url)
        @proxy = proxy
      end

      def post(path, body: nil, params: {})
        uri = URI.join(@uri, path)
        uri.query = URI.encode_www_form(params) unless params.empty?

        req = Net::HTTP::Post.new(uri)
        @headers.each { |k, v| req[k] = v }
        req.body = body if body

        Net::HTTP.start(uri.host, uri.port, *proxy_start_args, use_ssl: uri.scheme == "https", open_timeout: @timeout, read_timeout: @timeout) do |http|
          resp = http.request(req)
          Response.new(resp.code.to_i, resp.body, resp.to_hash)
        end
      rescue SocketError, Net::OpenTimeout, Net::ReadTimeout => e
        raise Altertable::NetworkError.new("Timeout: #{e.message}", e)
      rescue StandardError => e
        raise Altertable::NetworkError.new(e.message, e)
      end

      private

      # Net::HTTP.start's p_addr defaults to :ENV; returning [] here preserves that.
      # Passing an explicit nil p_addr (i.e. [nil]) is how Net::HTTP disables proxying.
      def proxy_start_args
        return [] if @proxy.nil?
        return [nil] if @proxy == false

        proxy_uri = URI.parse(@proxy)
        [proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password]
      end
    end
  end
end
