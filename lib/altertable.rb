# frozen_string_literal: true

require_relative "altertable/version"
require_relative "altertable/errors"
require_relative "altertable/client"

module Altertable
  class << self
    def init(api_key, options = {})
      @client = Client.new(api_key, options)
    end

    def track(event, distinct_id, **options)
      client.track(event, distinct_id, **options)
    end

    def identify(user_id, **options)
      client.identify(user_id, **options)
    end

    def alias(distinct_id, new_user_id, **options)
      client.alias(distinct_id, new_user_id, **options)
    end

    def track_batch(events)
      client.track_batch(events)
    end

    def identify_batch(identifies)
      client.identify_batch(identifies)
    end

    def alias_batch(aliases)
      client.alias_batch(aliases)
    end

    def client
      raise ConfigurationError, "Altertable client not initialized. Call Altertable.init(api_key) first." unless @client

      @client
    end
  end
end
