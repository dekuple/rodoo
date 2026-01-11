# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module Rodoo
  class Connection
    attr_reader :config

    def initialize(config)
      @config = config
      @uri = URI.parse(config.url)
    end

    def execute(model, method, params = {})
      path = "/json/2/#{model}/#{method}"
      response = post(path, params)
      handle_response(response)
    end

    private

    def post(path, payload)
      http = build_http_client
      request = build_request(path, payload)
      log_request(path, payload)
      response = http.request(request)
      log_response(response)
      response
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise TimeoutError.new("Request timed out", original_error: e)
    rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET => e
      raise ConnectionError.new("Failed to connect to #{config.url}", original_error: e)
    end

    def build_http_client
      Net::HTTP.new(@uri.host, @uri.port).tap do |http|
        http.use_ssl = @uri.scheme == "https"
        http.read_timeout = config.timeout
        http.open_timeout = config.open_timeout
      end
    end

    def build_request(path, payload)
      Net::HTTP::Post.new(path).tap do |request|
        request["Content-Type"] = "application/json"
        request["Authorization"] = "Bearer #{config.api_key}" if config.api_key
        request.body = payload.to_json
      end
    end

    def handle_response(response)
      case response
      when Net::HTTPSuccess
        parse_response(response.body)
      when Net::HTTPUnauthorized
        raise AuthenticationError.new("Invalid credentials", code: response.code)
      when Net::HTTPForbidden
        raise AccessDeniedError.new("Access denied", code: response.code)
      when Net::HTTPNotFound
        raise NotFoundError.new("Endpoint not found", code: response.code)
      else
        raise_api_error(response)
      end
    end

    def raise_api_error(response)
      error_data = parse_error_body(response.body)
      unless error_data
        raise APIError.new("HTTP #{response.code}: #{response.message}", code: response.code)
      end

      error_class = map_odoo_exception(error_data[:name])
      message = error_data[:message] || "HTTP #{response.code}: #{response.message}"
      raise error_class.new(message, code: response.code, data: error_data)
    end

    def parse_error_body(body)
      return nil if body.nil? || body.empty?

      JSON.parse(body, symbolize_names: true)
    rescue JSON::ParserError
      nil
    end

    def map_odoo_exception(exception_name)
      case exception_name
      when /ValidationError/, /UserError/
        ValidationError
      when /AccessError/, /AccessDenied/
        AccessDeniedError
      when /MissingError/
        NotFoundError
      else
        APIError
      end
    end

    def parse_response(body)
      return nil if body.nil? || body.empty?

      JSON.parse(body, symbolize_names: true)
    rescue JSON::ParserError => e
      raise Error.new("Invalid JSON response", original_error: e)
    end

    def log_request(path, payload)
      return unless config.logger

      if config.log_level == :debug
        config.logger.debug("[Rodoo] POST #{path} #{payload.to_json}")
      else
        config.logger.info("[Rodoo] POST #{path}")
      end
    end

    def log_response(response)
      return unless config.logger

      if config.log_level == :debug
        config.logger.debug("[Rodoo] Response #{response.code}: #{response.body}")
      else
        config.logger.info("[Rodoo] Response #{response.code}")
      end
    end
  end
end
