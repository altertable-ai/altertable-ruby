# frozen_string_literal: true

require "json"
require "time"
require_relative "errors"
require_relative "adapters"

module Altertable
  class Client
    DEFAULT_BASE_URL = "https://api.altertable.ai"
    DEFAULT_TIMEOUT = 5
    DEFAULT_ENVIRONMENT = "production"

    def initialize(api_key, options = {})
      raise ConfigurationError, "API Key is required" if api_key.nil? || api_key.empty?

      @api_key = api_key
      @base_url = options[:base_url] || DEFAULT_BASE_URL
      @environment = options[:environment] || DEFAULT_ENVIRONMENT
      @timeout = options[:request_timeout] || DEFAULT_TIMEOUT
      @release = options[:release]
      @debug = options[:debug] || false
      @on_error = options[:on_error]

      # Initialize adapter
      adapter_name = options[:adapter]
      headers = {
        "X-API-Key" => @api_key,
        "Content-Type" => "application/json"
      }
      @adapter = select_adapter(adapter_name, { base_url: @base_url, timeout: @timeout, headers: headers })
    end

    def track(event, distinct_id, **options)
      properties = options[:properties] || {}
      timestamp = options[:timestamp] || Time.now.utc.iso8601(3)
      payload = {
        timestamp: timestamp,
        event: event,
        environment: @environment,
        distinct_id: distinct_id,
        properties: {
          "$lib": "altertable-ruby",
          "$lib_version": Altertable::VERSION
        }.merge(properties)
      }
      payload[:properties]["$release"] = @release if @release
      payload[:anonymous_id] = options[:anonymous_id] if options.key?(:anonymous_id)
      payload[:device_id] = options[:device_id] if options.key?(:device_id)

      post("/track", payload)
    end

    def identify(user_id, **options)
      traits = options[:traits] || {}
      timestamp = options[:timestamp] || Time.now.utc.iso8601(3)
      payload = {
        timestamp: timestamp,
        environment: @environment,
        distinct_id: user_id,
        traits: traits
      }
      payload[:anonymous_id] = options[:anonymous_id] if options.key?(:anonymous_id)
      payload[:device_id] = options[:device_id] if options.key?(:device_id)

      post("/identify", payload)
    end

    def alias(distinct_id, new_user_id, **options)
      timestamp = options[:timestamp] || Time.now.utc.iso8601(3)
      payload = {
        timestamp: timestamp,
        environment: @environment,
        distinct_id: distinct_id,
        new_user_id: new_user_id
      }

      post("/alias", payload)
    end

    private

    def select_adapter(name, options)
      case name
      when :faraday
        Adapters::FaradayAdapter.new(**options)
      when :httpx
        Adapters::HttpxAdapter.new(**options)
      when :net_http
        Adapters::NetHttpAdapter.new(**options)
      else
        # Auto-detect
        if defined?(Faraday) || try_require("faraday")
          Adapters::FaradayAdapter.new(**options)
        elsif defined?(HTTPX) || try_require("httpx")
          Adapters::HttpxAdapter.new(**options)
        else
          Adapters::NetHttpAdapter.new(**options)
        end
      end
    end

    def try_require(gem_name)
      require gem_name
      true
    rescue LoadError
      false
    end

    def post(path, payload)
      res = @adapter.post(path, body: payload.to_json)
      handle_response(res)
    rescue StandardError => e
      handle_error(e)
    end

    def handle_response(res)
      case res.status
      when 200..299
        JSON.parse(res.body) rescue {}
      when 422
        error_data = JSON.parse(res.body) rescue {}
        raise ApiError.new("Unprocessable Entity: #{error_data["message"]}", res.status, error_data)
      else
        raise ApiError.new("HTTP Error: #{res.status}", res.status)
      end
    end

    def handle_error(error)
      wrapped_error = if error.is_a?(AltertableError)
                        error
                      else
                        AltertableError.new(error.message, error)
                      end

      @on_error&.call(wrapped_error) if @on_error
      raise wrapped_error
    end
  end
end
