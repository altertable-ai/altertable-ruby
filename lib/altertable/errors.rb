# frozen_string_literal: true

module Altertable
  class AltertableError < StandardError
    attr_reader :cause

    def initialize(message, cause = nil)
      super(message)
      @cause = cause
    end
  end

  class ConfigurationError < AltertableError; end

  class ApiError < AltertableError
    attr_reader :status, :details

    def initialize(message, status, details = {})
      super(message)
      @status = status
      @details = details
    end
  end

  class NetworkError < AltertableError; end
end
