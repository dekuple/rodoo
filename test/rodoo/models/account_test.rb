# frozen_string_literal: true

require "test_helper"

class AccountTest < Minitest::Test
  def test_model_name
    assert_equal "account.account", Rodoo::Account.model_name
  end

  def test_inherits_from_model
    assert Rodoo::Account < Rodoo::Model
  end

  def test_account_responds_to_class_query_methods
    assert_respond_to Rodoo::Account, :find
    assert_respond_to Rodoo::Account, :where
    assert_respond_to Rodoo::Account, :all
    assert_respond_to Rodoo::Account, :create
    assert_respond_to Rodoo::Account, :execute
  end
end
