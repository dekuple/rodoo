# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rodoo"

require "minitest/autorun"
require "webmock/minitest"

# Base test class with common setup and helpers
class RodooTestCase < Minitest::Test
  def setup
    configure_rodoo
  end

  def teardown
    Rodoo.reset!
    WebMock.reset!
  end

  private

  def configure_rodoo(url: "https://example.com", api_key: "test_key")
    Rodoo.configure do |c|
      c.url = url
      c.api_key = api_key
    end
  end

  def stub_odoo(model, method, response:, status: 200)
    stub_request(:post, "https://example.com/json/2/#{model}/#{method}")
      .to_return(
        status: status,
        body: response.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_odoo_error(model, method, error_name:, message:, status: 422)
    body = {
      name: error_name,
      message: message,
      arguments: [message],
      context: {},
      debug: "Traceback..."
    }

    stub_request(:post, "https://example.com/json/2/#{model}/#{method}")
      .to_return(
        status: status,
        body: body.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def last_request_body
    last_request = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.last
    JSON.parse(last_request.body, symbolize_names: true)
  end

  def request_bodies
    WebMock::RequestRegistry.instance.requested_signatures.hash.keys.map do |request|
      JSON.parse(request.body, symbolize_names: true)
    end
  end
end

# Test model for model tests
class TestEntity < Rodoo::Model
  model_name "test.entity"
end
