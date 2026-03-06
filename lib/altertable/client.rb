# frozen_string_literal: true

require "net/http"
require "json"
require "time"
require_relative "errors"

module Altertable
  class Client
    DEFAULT_BASE_URL = "https://api.altertable.ai"
    DEFAULT_TIMEOUT = 5
    DEFAULT_ENVIRONMENT = "production"

    RESERVED_USER_IDS = %w[
      anonymous_id anonymous distinct_id distinctid false guest
      id not_authenticated true undefined user_id user
      visitor_id visitor
    ].freeze

    RESERVED_USER_IDS_CASE_SENSITIVE = ["[object Object]", "0", "NaN", "none", "None", "null"].freeze

    def initialize(api_key, options = {})
      raise ConfigurationError, "API Key is required" if api_key.nil? || api_key.empty?

      @api_key = api_key
      @base_url = options[:base_url] || DEFAULT_BASE_URL
      @environment = options[:environment] || DEFAULT_ENVIRONMENT
      @timeout = options[:request_timeout] || DEFAULT_TIMEOUT
      @release = options[:release]
      @debug = options[:debug] || false
      @on_error = options[:on_error]
    end

    def track(event, properties = {})
      payload = {
        timestamp: Time.now.utc.iso8601(3),
        event: event,
        environment: @environment,
        properties: {
          "$lib": "altertable-ruby",
          "$lib_version": Altertable::VERSION
        }.merge(properties)
      }
      payload[:properties]["$release"] = @release if @release

      post("/track", payload)
    end

    def identify(user_id, traits = {})
      validate_user_id!(user_id)

      payload = {
        timestamp: Time.now.utc.iso8601(3),
        environment: @environment,
        distinct_id: user_id,
        traits: traits
      }

      post("/identify", payload)
    end

    def alias(new_user_id, previous_id)
      validate_user_id!(new_user_id)

      payload = {
        timestamp: Time.now.utc.iso8601(3),
        environment: @environment,
        distinct_id: previous_id,
        new_user_id: new_user_id
      }

      post("/alias", payload)
    end

    private

    def validate_user_id!(user_id)
      return if user_id.nil?

      id_str = user_id.to_s
      if RESERVED_USER_IDS.include?(id_str.downcase) || RESERVED_USER_IDS_CASE_SENSITIVE.include?(id_str)
        raise ArgumentError, "Reserved User ID: #{user_id}"
      end
    end

    def post(path, payload)
      uri = URI("#{@base_url}#{path}")
      req = Net::HTTP::Post.new(uri)
      req["X-API-Key"] = @api_key
      req["Content-Type"] = "application/json"
      req.body = payload.to_json

      begin
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", read_timeout: @timeout) do |http|
          http.request(req)
        end

        handle_response(res)
      rescue StandardError => e
        handle_error(e)
      end
    end

    def handle_response(res)
      case res.code.to_i
      when 200..299
        JSON.parse(res.body) rescue {}
      when 422
        error_data = JSON.parse(res.body) rescue {}
        raise ApiError.new("Unprocessable Entity: #{error_data["message"]}", res.code, error_data)
      else
        raise ApiError.new("HTTP Error: #{res.code}", res.code)
      end
    end

    def handle_error(error)
      wrapped_error = if error.is_a?(AltertableError)
                        error
                      elsif error.is_a?(Net::ReadTimeout) || error.is_a?(Net::OpenTimeout)
                        NetworkError.new("Timeout: #{error.message}", error)
                      else
                        AltertableError.new(error.message, error)
                      end

      @on_error&.call(wrapped_error)
      raise wrapped_error
    end
  end
end
