# frozen_string_literal: true

require "test_helper"

class ContactTest < Minitest::Test
  def test_model_name
    assert_equal "res.partner", Rodoo::Contact.model_name
  end

  def test_inherits_from_model
    assert Rodoo::Contact < Rodoo::Model
  end

  def test_contact_responds_to_class_query_methods
    assert_respond_to Rodoo::Contact, :find
    assert_respond_to Rodoo::Contact, :where
    assert_respond_to Rodoo::Contact, :all
    assert_respond_to Rodoo::Contact, :create
    assert_respond_to Rodoo::Contact, :execute
  end
end
