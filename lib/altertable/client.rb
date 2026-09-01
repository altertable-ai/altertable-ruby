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
      @adapter = select_adapter(adapter_name, { base_url: @base_url, timeout: @timeout, headers: headers, proxy: options[:proxy] })
    end

    def track(event, distinct_id, **options)
      post("/track", track_payload(event, distinct_id, options))
    end

    def track_batch(events)
      payloads = map_batch(events, "events") { |item| track_payload_from_item(item) }
      post("/track", payloads)
    end

    def identify(user_id, **options)
      post("/identify", identify_payload(user_id, options))
    end

    def identify_batch(identifies)
      payloads = map_batch(identifies, "identifies") { |item| identify_payload_from_item(item) }
      post("/identify", payloads)
    end

    def alias(distinct_id, new_user_id, **options)
      post("/alias", alias_payload(distinct_id, new_user_id, options))
    end

    def alias_batch(aliases)
      payloads = map_batch(aliases, "aliases") { |item| alias_payload_from_item(item) }
      post("/alias", payloads)
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

    def map_batch(items, name, &block)
      raise ArgumentError, "#{name} must be a non-empty Array" unless items.is_a?(Array) && !items.empty?

      items.map(&block)
    end

    def item_value(item, key)
      if item.key?(key)
        item[key]
      elsif item.key?(key.to_s)
        item[key.to_s]
      end
    end

    def item_options(item, *keys)
      keys.each_with_object({}) do |key, opts|
        opts[key] = item_value(item, key) if item.key?(key) || item.key?(key.to_s)
      end
    end

    def blank?(value)
      value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end

    def default_timestamp
      Time.now.utc.iso8601(3)
    end

    def track_payload_from_item(item)
      event = item_value(item, :event)
      distinct_id = item_value(item, :distinct_id)
      raise ArgumentError, "event is required" if blank?(event)
      raise ArgumentError, "distinct_id is required" if blank?(distinct_id)

      track_payload(event, distinct_id, item_options(item, :properties, :anonymous_id, :device_id, :timestamp))
    end

    def identify_payload_from_item(item)
      user_id = item_value(item, :user_id)
      raise ArgumentError, "user_id is required" if blank?(user_id)

      identify_payload(user_id, item_options(item, :traits, :anonymous_id, :device_id, :timestamp))
    end

    def alias_payload_from_item(item)
      distinct_id = item_value(item, :distinct_id)
      new_user_id = item_value(item, :new_user_id)
      raise ArgumentError, "distinct_id is required" if blank?(distinct_id)
      raise ArgumentError, "new_user_id is required" if blank?(new_user_id)

      alias_payload(distinct_id, new_user_id, item_options(item, :timestamp))
    end

    def track_payload(event, distinct_id, options)
      properties = options[:properties] || {}
      payload = {
        timestamp: options[:timestamp] || default_timestamp,
        event: event,
        environment: @environment,
        distinct_id: distinct_id,
        properties: {
          '$lib': "altertable-ruby",
          '$lib_version': Altertable::VERSION
        }.merge(properties)
      }
      payload[:properties]["$release"] = @release if @release
      payload[:anonymous_id] = options[:anonymous_id] if options.key?(:anonymous_id)
      payload[:device_id] = options[:device_id] if options.key?(:device_id)
      payload
    end

    def identify_payload(user_id, options)
      payload = {
        timestamp: options[:timestamp] || default_timestamp,
        environment: @environment,
        distinct_id: user_id,
        traits: options[:traits] || {}
      }
      payload[:anonymous_id] = options[:anonymous_id] if options.key?(:anonymous_id)
      payload[:device_id] = options[:device_id] if options.key?(:device_id)
      payload
    end

    def alias_payload(distinct_id, new_user_id, options)
      {
        timestamp: options[:timestamp] || default_timestamp,
        environment: @environment,
        distinct_id: distinct_id,
        new_user_id: new_user_id
      }
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
        begin
          JSON.parse(res.body)
        rescue StandardError
          {}
        end
      when 422
        error_data = begin
                       JSON.parse(res.body)
        rescue StandardError
                       {}
        end
        raise ApiError.new("Unprocessable Entity: #{error_data['message']}", res.status, error_data)
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

      @on_error&.call(wrapped_error)
      raise wrapped_error
    end
  end
end
