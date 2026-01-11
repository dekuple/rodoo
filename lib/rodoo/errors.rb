# frozen_string_literal: true

module Rodoo
  class Error < StandardError
    attr_reader :original_error

    def initialize(message = nil, original_error: nil)
      @original_error = original_error
      super(message)
    end
  end

  class ConfigurationError < Error; end
  class ConnectionError < Error; end
  class TimeoutError < ConnectionError; end

  class APIError < Error
    attr_reader :code, :data

    def initialize(message = nil, code: nil, data: nil, **kwargs)
      @code = code
      @data = data
      super(message, **kwargs)
    end
  end

  class AuthenticationError < APIError; end
  class NotFoundError < APIError; end
  class ValidationError < APIError; end
  class AccessDeniedError < APIError; end
end
