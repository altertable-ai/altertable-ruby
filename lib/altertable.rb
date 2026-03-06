# frozen_string_literal: true

require_relative "altertable/version"
require_relative "altertable/errors"
require_relative "altertable/client"

module Altertable
  class << self
    def init(api_key, options = {})
      @client = Client.new(api_key, options)
    end

    def track(event, properties = {})
      client.track(event, properties)
    end

    def identify(user_id, traits = {})
      client.identify(user_id, traits)
    end

    def alias(new_user_id, previous_id)
      client.alias(new_user_id, previous_id)
    end

    def client
      raise ConfigurationError, "Altertable client not initialized. Call Altertable.init(api_key) first." unless @client

      @client
    end
  end
end
