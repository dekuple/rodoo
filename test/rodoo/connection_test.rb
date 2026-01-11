# frozen_string_literal: true

require "test_helper"

class ConnectionTest < RodooTestCase
  ENDPOINT = "https://example.com/json/2/res.partner/search_read"

  # Data-driven tests for HTTP status code to exception mapping
  HTTP_ERROR_CASES = {
    "http_403_access_denied" => [403, Rodoo::AccessDeniedError, "Access denied"],
    "http_404_not_found" => [404, Rodoo::NotFoundError, "Endpoint not found"]
  }.freeze

  HTTP_ERROR_CASES.each do |name, (status, error_class, message)|
    define_method("test_#{name}") do
      stub_request(:post, ENDPOINT).to_return(status: status, body: "")

      error = assert_raises(error_class) { execute_request }
      assert_equal message, error.message
    end
  end

  # Data-driven tests for Odoo exception to Ruby exception mapping
  ODOO_EXCEPTION_CASES = {
    "validation_error" => ["odoo.exceptions.ValidationError", Rodoo::ValidationError, 422],
    "access_error" => ["odoo.exceptions.AccessError", Rodoo::AccessDeniedError, 500],
    "missing_error" => ["odoo.exceptions.MissingError", Rodoo::NotFoundError, 500],
    "user_error" => ["odoo.exceptions.UserError", Rodoo::ValidationError, 400],
    "unknown_exception" => ["odoo.exceptions.SomeNewException", Rodoo::APIError, 500]
  }.freeze

  ODOO_EXCEPTION_CASES.each do |name, (odoo_exception, error_class, status)|
    define_method("test_odoo_#{name}_mapping") do
      message = "Test error message"
      stub_odoo_exception(odoo_exception, message, status: status)

      error = assert_raises(error_class) { execute_request }
      assert_equal message, error.message
    end
  end

  def test_validation_error_includes_full_error_data
    stub_odoo_error("res.partner", "search_read",
                    error_name: "odoo.exceptions.ValidationError",
                    message: "Missing required field")

    error = assert_raises(Rodoo::ValidationError) { execute_request }

    assert_equal "422", error.code
    assert_equal "odoo.exceptions.ValidationError", error.data[:name]
    assert_equal "Traceback...", error.data[:debug]
  end

  def test_error_data_contains_full_response
    stub_request(:post, ENDPOINT).to_return(
      status: 422,
      body: {
        name: "odoo.exceptions.ValidationError",
        message: "Error",
        arguments: %w[arg1 arg2],
        context: { key: "value" },
        debug: "Full trace"
      }.to_json
    )

    error = assert_raises(Rodoo::ValidationError) { execute_request }

    assert_equal %w[arg1 arg2], error.data[:arguments]
    assert_equal({ key: "value" }, error.data[:context])
    assert_equal "Full trace", error.data[:debug]
  end

  def test_non_json_error_body_falls_back_to_http_message
    stub_request(:post, ENDPOINT).to_return(status: [500, "Internal Server Error"], body: "Not JSON")

    error = assert_raises(Rodoo::APIError) { execute_request }
    assert_equal "HTTP 500: Internal Server Error", error.message
  end

  def test_empty_error_body_falls_back_to_http_message
    stub_request(:post, ENDPOINT).to_return(status: [500, "Internal Server Error"], body: "")

    error = assert_raises(Rodoo::APIError) { execute_request }
    assert_equal "HTTP 500: Internal Server Error", error.message
  end

  def test_successful_request_returns_parsed_json
    stub_odoo("res.partner", "search_read", response: [{ id: 1, name: "Test" }])

    result = execute_request(domain: [])

    assert_equal [{ id: 1, name: "Test" }], result
  end

  def test_request_includes_authorization_header
    stub_odoo("res.partner", "search_read", response: [])

    execute_request

    assert_requested :post, ENDPOINT, headers: { "Authorization" => "Bearer test_key" }
  end

  def test_request_sends_json_content_type
    stub_odoo("res.partner", "search_read", response: [])

    execute_request

    assert_requested :post, ENDPOINT, headers: { "Content-Type" => "application/json" }
  end

  def test_timeout_raises_timeout_error
    stub_request(:post, ENDPOINT).to_timeout

    assert_raises(Rodoo::TimeoutError) { execute_request }
  end

  def test_connection_refused_raises_connection_error
    stub_request(:post, ENDPOINT).to_raise(Errno::ECONNREFUSED)

    assert_raises(Rodoo::ConnectionError) { execute_request }
  end

  private

  def execute_request(params = {})
    Rodoo.connection.execute("res.partner", "search_read", params)
  end

  def stub_odoo_exception(name, message, status:)
    stub_request(:post, ENDPOINT).to_return(
      status: status,
      body: { name: name, message: message }.to_json
    )
  end
end
