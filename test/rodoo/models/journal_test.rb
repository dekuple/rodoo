# frozen_string_literal: true

require "test_helper"

class JournalTest < Minitest::Test
  def test_model_name
    assert_equal "account.journal", Rodoo::Journal.model_name
  end

  def test_inherits_from_model
    assert Rodoo::Journal < Rodoo::Model
  end

  def test_journal_responds_to_class_query_methods
    assert_respond_to Rodoo::Journal, :find
    assert_respond_to Rodoo::Journal, :where
    assert_respond_to Rodoo::Journal, :all
    assert_respond_to Rodoo::Journal, :create
    assert_respond_to Rodoo::Journal, :execute
  end
end
