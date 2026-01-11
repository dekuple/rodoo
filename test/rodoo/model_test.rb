# frozen_string_literal: true

require "test_helper"

class ModelTest < RodooTestCase
  # === Class Methods ===

  def test_model_name_sets_and_returns_name
    model_class = Class.new(Rodoo::Model) { model_name "test.model" }
    assert_equal "test.model", model_class.model_name
  end

  # === find ===

  def test_find_returns_model_instance
    stub_odoo("test.entity", "read", response: [{ id: 42, name: "Found" }])

    record = TestEntity.find(42)

    assert_instance_of TestEntity, record
    assert_equal 42, record.id
    assert_equal "Found", record.name
  end

  def test_find_raises_not_found_for_empty_result
    stub_odoo("test.entity", "read", response: [])
    assert_raises(Rodoo::NotFoundError) { TestEntity.find(999) }
  end

  def test_find_raises_not_found_for_nil_result
    stub_odoo("test.entity", "read", response: nil)
    assert_raises(Rodoo::NotFoundError) { TestEntity.find(999) }
  end

  # === where ===

  def test_where_returns_array_of_instances
    stub_search_read([{ id: 1, name: "First" }, { id: 2, name: "Second" }])

    records = TestEntity.where([["is_company", "=", true]])

    assert_equal 2, records.length
    assert_instance_of TestEntity, records.first
    assert_equal %w[First Second], records.map(&:name)
  end

  def test_where_passes_options_to_api
    stub_search_read([])

    TestEntity.where([["name", "=", "Test"]], fields: %w[name email], limit: 10, offset: 5)

    expected = { domain: [["name", "=", "Test"]], fields: %w[name email], limit: 10, offset: 5 }
    assert_equal expected, last_request_body
  end

  def test_where_omits_nil_params
    stub_search_read([])
    TestEntity.where([])
    assert_equal({ domain: [] }, last_request_body)
  end

  def test_where_with_keyword_arguments
    stub_search_read([])

    TestEntity.where(name: "Acme", is_company: true)

    assert_includes last_request_body[:domain], ["name", "=", "Acme"]
    assert_includes last_request_body[:domain], ["is_company", "=", true]
  end

  def test_where_with_hash
    stub_search_read([])

    TestEntity.where({ name: "Acme", active: true })

    assert_includes last_request_body[:domain], ["name", "=", "Acme"]
    assert_includes last_request_body[:domain], ["active", "=", true]
  end

  def test_where_with_nil_returns_empty_domain
    stub_search_read([])
    TestEntity.where
    assert_equal({ domain: [] }, last_request_body)
  end

  def test_where_raises_on_invalid_string_condition
    assert_raises(ArgumentError) { TestEntity.where("invalid condition without operator") }
  end

  # === String Domain Parsing (data-driven) ===

  STRING_DOMAIN_CASES = {
    "simple equality" => ["name = 'Acme Corp'", [["name", "=", "Acme Corp"]]],
    "greater than" => ["credit_limit > 1000", [["credit_limit", ">", 1000]]],
    "integer value" => ["count = 42", [["count", "=", 42]]],
    "negative integer" => ["balance = -100", [["balance", "=", -100]]],
    "float value" => ["price = 19.99", [["price", "=", 19.99]]],
    "boolean true" => ["active = true", [["active", "=", true]]],
    "boolean false" => ["active = false", [["active", "=", false]]],
    "double quoted string" => ['name = "John Doe"', [["name", "=", "John Doe"]]],
    "single quoted string" => ["name = 'John Doe'", [["name", "=", "John Doe"]]],
    "unquoted identifier" => ["ref = ABC123", [["ref", "=", "ABC123"]]],
    "like operator" => ["name like '%test%'", [["name", "like", "%test%"]]],
    "ilike operator" => ["name ilike '%TEST%'", [["name", "ilike", "%TEST%"]]]
  }.freeze

  STRING_DOMAIN_CASES.each do |description, (input, expected)|
    define_method("test_where_parses_#{description.tr(" ", "_")}") do
      stub_search_read([])
      TestEntity.where(input)
      assert_equal expected, last_request_body[:domain]
    end
  end

  # Operator mapping tests
  OPERATOR_CASES = {
    "not_equal" => ["!=", "!="],
    "not_equal_alt" => ["<>", "!="],
    "less_than_or_equal" => ["<=", "<="],
    "greater_than_or_equal" => [">=", ">="],
    "less_than" => ["<", "<"],
    "greater_than" => [">", ">"]
  }.freeze

  OPERATOR_CASES.each do |name, (input_op, expected_op)|
    define_method("test_where_parses_operator_#{name}") do
      stub_search_read([])
      TestEntity.where("age #{input_op} 18")
      assert_equal [["age", expected_op, 18]], last_request_body[:domain]
    end
  end

  def test_where_with_array_of_strings
    stub_search_read([])

    TestEntity.where(["credit_limit > 1000", "active = true"])

    assert_equal [["credit_limit", ">", 1000], ["active", "=", true]], last_request_body[:domain]
  end

  # === all ===

  def test_all_calls_where_with_empty_domain
    stub_search_read([{ id: 1, name: "Record" }])

    records = TestEntity.all(limit: 5)

    assert_equal 1, records.length
    assert_equal({ domain: [], limit: 5 }, last_request_body)
  end

  # === find_by ===

  def test_find_by_returns_first_matching_record
    stub_search_read([{ id: 42, email: "john@example.com" }])

    record = TestEntity.find_by(email: "john@example.com")

    assert_instance_of TestEntity, record
    assert_equal 42, record.id
  end

  def test_find_by_returns_nil_when_not_found
    stub_search_read([])
    assert_nil TestEntity.find_by(email: "notfound@example.com")
  end

  def test_find_by_passes_limit_one
    stub_search_read([])

    TestEntity.find_by(email: "test@example.com")

    assert_equal 1, last_request_body[:limit]
  end

  def test_find_by_with_multiple_conditions
    stub_search_read([])

    TestEntity.find_by(name: "Acme", is_company: true)

    assert_includes last_request_body[:domain], ["name", "=", "Acme"]
    assert_includes last_request_body[:domain], ["is_company", "=", true]
  end

  def test_find_by_with_string_condition
    stub_search_read([{ id: 1, credit_limit: 5000 }])

    TestEntity.find_by("credit_limit > 1000")

    assert_equal [["credit_limit", ">", 1000]], last_request_body[:domain]
  end

  def test_find_by_with_raw_domain
    stub_search_read([{ id: 2, name: "Test" }])

    TestEntity.find_by([["name", "ilike", "%test%"]])

    assert_equal [["name", "ilike", "%test%"]], last_request_body[:domain]
  end

  # === find_by! ===

  def test_find_by_bang_returns_record_when_found
    stub_search_read([{ id: 42, email: "john@example.com" }])

    record = TestEntity.find_by!(email: "john@example.com")

    assert_instance_of TestEntity, record
    assert_equal 42, record.id
  end

  def test_find_by_bang_raises_not_found_when_empty
    stub_search_read([])

    error = assert_raises(Rodoo::NotFoundError) { TestEntity.find_by!(email: "notfound@example.com") }

    assert_includes error.message, "test.entity"
    assert_includes error.message, "email"
  end

  # === create ===

  def test_create_returns_new_record
    stub_odoo("test.entity", "create", response: [123])
    stub_odoo("test.entity", "read", response: [{ id: 123, name: "Created" }])

    record = TestEntity.create(name: "Created")

    assert_instance_of TestEntity, record
    assert_equal 123, record.id
    assert_equal "Created", record.name
  end

  def test_create_passes_vals_list
    stub_odoo("test.entity", "create", response: [1])
    stub_odoo("test.entity", "read", response: [{ id: 1 }])

    TestEntity.create(name: "Test", email: "test@example.com")

    assert_equal({ vals_list: [{ name: "Test", email: "test@example.com" }] }, request_bodies.first)
  end

  # === Instance: initialization ===

  def test_new_returns_unpersisted_instance
    record = TestEntity.new(name: "Draft")

    assert_instance_of TestEntity, record
    refute record.persisted?
    assert_equal "Draft", record.name
  end

  def test_initialize_with_attributes
    record = TestEntity.new(id: 1, name: "Test", email: "test@example.com")

    assert_equal 1, record.id
    assert_equal "Test", record.name
    assert_equal "test@example.com", record.email
  end

  def test_initialize_with_string_keys
    record = TestEntity.new("id" => 1, "name" => "Test")

    assert_equal 1, record.id
    assert_equal "Test", record.name
  end

  def test_initialize_with_nil_attributes
    record = TestEntity.new(nil)

    assert_nil record.id
    assert_equal({}, record.to_h)
  end

  # === Instance: persisted? ===

  def test_persisted_with_id
    assert TestEntity.new(id: 1).persisted?
  end

  def test_persisted_without_id
    refute TestEntity.new(name: "Test").persisted?
  end

  # === Instance: dynamic attributes ===

  def test_dynamic_attribute_setter
    record = TestEntity.new({})

    record.name = "New Name"
    record.email = "new@example.com"

    assert_equal "New Name", record.name
    assert_equal "new@example.com", record.email
  end

  def test_unknown_attribute_returns_nil
    assert_nil TestEntity.new({}).unknown_attribute
  end

  def test_to_h_returns_attributes_copy
    record = TestEntity.new(id: 1, name: "Test")

    result = record.to_h
    result[:name] = "Modified"

    assert_equal "Test", record.name
  end

  def test_respond_to_for_attributes
    record = TestEntity.new(name: "Test")

    assert record.respond_to?(:name)
    assert record.respond_to?(:name=)
    assert record.respond_to?(:any_attribute)
    assert record.respond_to?(:any_attribute=)
  end

  def test_inspect_includes_class_and_id
    record = TestEntity.new(id: 42, name: "Test")

    assert_includes record.inspect, "TestEntity"
    assert_includes record.inspect, "id=42"
  end

  # === Instance: persistence ===

  def test_update_calls_write_and_merges_attributes
    stub_odoo("test.entity", "write", response: true)
    record = TestEntity.new(id: 42, name: "Original")

    record.update(name: "Updated", email: "new@example.com")

    assert_equal({ ids: [42], vals: { name: "Updated", email: "new@example.com" } }, last_request_body)
    assert_equal "Updated", record.name
    assert_equal "new@example.com", record.email
  end

  def test_update_raises_for_unpersisted_record
    assert_raises(Rodoo::Error) { TestEntity.new(name: "Test").update(name: "New") }
  end

  def test_reload_refreshes_attributes
    response = [{ id: 42, name: "Refreshed", email: "refreshed@example.com" }]
    stub_odoo("test.entity", "read", response: response)
    record = TestEntity.new(id: 42, name: "Original")

    record.reload

    assert_equal "Refreshed", record.name
    assert_equal "refreshed@example.com", record.email
  end

  def test_reload_raises_for_unpersisted_record
    assert_raises(Rodoo::Error) { TestEntity.new(name: "Test").reload }
  end

  def test_save_creates_new_record_when_unpersisted
    stub_odoo("test.entity", "create", response: [99])
    stub_odoo("test.entity", "read", response: [{ id: 99, name: "Saved" }])
    record = TestEntity.new(name: "Draft")

    result = record.save

    assert_equal record, result
    assert_equal 99, record.id
    assert record.persisted?
  end

  def test_save_updates_existing_record_when_persisted
    stub_odoo("test.entity", "write", response: true)
    record = TestEntity.new(id: 42, name: "Updated")

    result = record.save

    assert_equal record, result
    assert_requested :post, "https://example.com/json/2/test.entity/write"
  end

  # === Instance: destroy ===

  def test_destroy_calls_unlink_api
    stub_odoo("test.entity", "unlink", response: true)
    record = TestEntity.new(id: 42, name: "To Delete")

    record.destroy

    assert_equal({ ids: [42] }, last_request_body)
    assert_requested :post, "https://example.com/json/2/test.entity/unlink"
  end

  def test_destroy_freezes_record
    stub_odoo("test.entity", "unlink", response: true)
    record = TestEntity.new(id: 42, name: "To Delete")

    record.destroy

    assert record.frozen?
  end

  def test_destroy_marks_record_as_destroyed
    stub_odoo("test.entity", "unlink", response: true)
    record = TestEntity.new(id: 42, name: "To Delete")

    refute record.destroyed?
    record.destroy
    assert record.destroyed?
  end

  def test_destroy_raises_for_unpersisted_record
    record = TestEntity.new(name: "Unpersisted")

    assert_raises(Rodoo::Error) { record.destroy }
  end

  def test_destroyed_returns_false_by_default
    record = TestEntity.new(id: 42, name: "Test")

    refute record.destroyed?
  end

  private

  def stub_search_read(response)
    stub_odoo("test.entity", "search_read", response: response)
  end
end
