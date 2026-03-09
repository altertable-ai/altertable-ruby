module Faraday; end
class Faraday::Error < StandardError; end
class Faraday::ServerError < Faraday::Error; end
class Faraday::ConnectionFailed < Faraday::Error; end
class Faraday::TimeoutError < Faraday::ServerError; end
module HTTPX; end
class HTTPX::Error < StandardError; end
class HTTPX::ErrorResponse; end
