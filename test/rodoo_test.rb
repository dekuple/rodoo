# frozen_string_literal: true

require "test_helper"

class RodooTest < RodooTestCase
  def test_has_version_number
    refute_nil Rodoo::VERSION
  end

  def test_configuration
    assert_equal "https://example.com", Rodoo.configuration.url
    assert_equal "test_key", Rodoo.configuration.api_key
  end

  def test_connection_returns_connection_instance
    assert_instance_of Rodoo::Connection, Rodoo.connection
  end

  def test_connection_is_memoized
    assert_same Rodoo.connection, Rodoo.connection
  end

  def test_reset_clears_connection
    original = Rodoo.connection
    Rodoo.reset!
    configure_rodoo(url: "https://other.com", api_key: "other_key")

    refute_same original, Rodoo.connection
  end

  def test_configure_resets_connection
    original = Rodoo.connection
    configure_rodoo(url: "https://other.com")

    refute_same original, Rodoo.connection
  end
end
