module Faraday; end
class Faraday::ConnectionFailed < StandardError; end
class Faraday::TimeoutError < StandardError; end
module HTTPX; end
class HTTPX::Error < StandardError; end
class HTTPX::ErrorResponse; end
