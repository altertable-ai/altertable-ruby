# typed: true

module Altertable
  VERSION = T.let(T.unsafe(nil), String)

  class AltertableError < StandardError
    sig { returns(T.nilable(Exception)) }
    attr_reader :cause

    sig { params(message: String, cause: T.nilable(Exception)).void }
    def initialize(message, cause = nil); end
  end

  class ConfigurationError < AltertableError; end

  class ApiError < AltertableError
    sig { returns(Integer) }
    attr_reader :status

    sig { returns(T::Hash[String, T.untyped]) }
    attr_reader :details

    sig { params(message: String, status: Integer, details: T::Hash[String, T.untyped]).void }
    def initialize(message, status, details = {}); end
  end

  class NetworkError < AltertableError; end

  class Client
    DEFAULT_BASE_URL = T.let(T.unsafe(nil), String)
    DEFAULT_TIMEOUT = T.let(T.unsafe(nil), Integer)
    DEFAULT_ENVIRONMENT = T.let(T.unsafe(nil), String)

    sig { params(api_key: String, options: T::Hash[Symbol, T.untyped]).void }
    def initialize(api_key, options = {}); end

    sig { params(event: String, distinct_id: String, options: T.untyped).returns(T.untyped) }
    def track(event, distinct_id, **options); end

    sig { params(user_id: String, options: T.untyped).returns(T.untyped) }
    def identify(user_id, **options); end

    sig { params(distinct_id: String, new_user_id: String, options: T.untyped).returns(T.untyped) }
    def alias(distinct_id, new_user_id, **options); end

    private

    sig { params(name: T.nilable(Symbol), options: T::Hash[Symbol, T.untyped]).returns(T.untyped) }
    def select_adapter(name, options); end

    sig { params(gem_name: String).returns(T::Boolean) }
    def try_require(gem_name); end

    sig { params(path: String, payload: T::Hash[T.any(Symbol, String), T.untyped]).returns(T.untyped) }
    def post(path, payload); end

    sig { params(res: T.untyped).returns(T.untyped) }
    def handle_response(res); end

    sig { params(error: Exception).returns(T.untyped) }
    def handle_error(error); end
  end

  module Adapters
    class Response
      sig { returns(Integer) }
      attr_reader :status

      sig { returns(String) }
      attr_reader :body

      sig { params(status: Integer, body: String).void }
      def initialize(status, body); end
    end

    class Base
      sig { params(base_url: String, timeout: T.any(Integer, Float), headers: T.nilable(T::Hash[String, String])).void }
      def initialize(base_url:, timeout:, headers: nil); end

      sig { params(path: String, body: T.nilable(String), params: T.nilable(T::Hash[T.any(Symbol, String), T.untyped]), block: T.nilable(T.proc.params(arg0: T.untyped).void)).returns(Response) }
      def post(path, body: nil, params: nil, &block); end
    end

    class FaradayAdapter < Base
      sig { params(base_url: String, timeout: T.any(Integer, Float), headers: T.nilable(T::Hash[String, String])).void }
      def initialize(base_url:, timeout:, headers: nil); end

      sig { params(path: String, body: T.nilable(String), params: T.nilable(T::Hash[T.any(Symbol, String), T.untyped]), block: T.nilable(T.proc.params(arg0: T.untyped).void)).returns(Response) }
      def post(path, body: nil, params: nil, &block); end

      private

      sig { params(resp: T.untyped).returns(Response) }
      def wrap_response(resp); end
    end

    class HttpxAdapter < Base
      sig { params(base_url: String, timeout: T.any(Integer, Float), headers: T.nilable(T::Hash[String, String])).void }
      def initialize(base_url:, timeout:, headers: nil); end

      sig { params(path: String, body: T.nilable(String), params: T.nilable(T::Hash[T.any(Symbol, String), T.untyped]), block: T.nilable(T.proc.params(arg0: T.untyped).void)).returns(Response) }
      def post(path, body: nil, params: nil, &block); end

      private

      sig { params(resp: T.untyped).returns(Response) }
      def wrap_response(resp); end
    end

    class NetHttpAdapter < Base
      sig { params(base_url: String, timeout: T.any(Integer, Float), headers: T.nilable(T::Hash[String, String])).void }
      def initialize(base_url:, timeout:, headers: nil); end

      sig { params(path: String, body: T.nilable(String), params: T.nilable(T::Hash[T.any(Symbol, String), T.untyped]), block: T.nilable(T.proc.params(arg0: T.untyped).void)).returns(Response) }
      def post(path, body: nil, params: nil, &block); end
    end
  end

  sig { params(api_key: String, options: T::Hash[Symbol, T.untyped]).returns(Client) }
  def self.init(api_key, options = {}); end

  sig { params(event: String, distinct_id: String, options: T.untyped).returns(T.untyped) }
  def self.track(event, distinct_id, **options); end

  sig { params(user_id: String, options: T.untyped).returns(T.untyped) }
  def self.identify(user_id, **options); end

  sig { params(distinct_id: String, new_user_id: String, options: T.untyped).returns(T.untyped) }
  def self.alias(distinct_id, new_user_id, **options); end

  sig { returns(Client) }
  def self.client; end
end
