# frozen_string_literal: true

module Rodoo
  class Configuration
    VALID_OPTIONS = %i[
      url
      api_key
      timeout
      open_timeout
      logger
      log_level
    ].freeze

    attr_accessor(*VALID_OPTIONS)

    DEFAULT_TIMEOUT = 30
    DEFAULT_OPEN_TIMEOUT = 10
    DEFAULT_LOG_LEVEL = :info

    def initialize
      @url = ENV.fetch("ODOO_URL", nil)
      @api_key = ENV.fetch("ODOO_API_KEY", nil)
      @timeout = DEFAULT_TIMEOUT
      @open_timeout = DEFAULT_OPEN_TIMEOUT
      @log_level = DEFAULT_LOG_LEVEL
    end

    def validate!
      raise ConfigurationError, "url is required" if url.nil? || url.empty?
      raise ConfigurationError, "api_key or username/password is required" unless api_key

      true
    end

    # Returns a hash of all options (useful for debugging)
    def to_h
      VALID_OPTIONS.each_with_object({}) do |key, hash|
        hash[key] = send(key)
      end
    end
  end
end
