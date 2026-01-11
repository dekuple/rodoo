# frozen_string_literal: true

require "test_helper"

class AccountingEntryTest < RodooTestCase
  def test_accounting_entry_where_with_array_domain
    stub_odoo("account.move", "search_read", response: [])

    Rodoo::AccountingEntry.where([["state", "=", "posted"]])

    assert_equal [["state", "=", "posted"]], last_request_body[:domain]
  end

  def test_accounting_entry_where_with_keyword_args
    stub_odoo("account.move", "search_read", response: [])

    Rodoo::AccountingEntry.where(state: "posted")

    assert_equal [["state", "=", "posted"]], last_request_body[:domain]
  end

  def test_accounting_entry_where_with_string_condition
    stub_odoo("account.move", "search_read", response: [])

    Rodoo::AccountingEntry.where("amount_total > 1000")

    assert_equal [["amount_total", ">", 1000]], last_request_body[:domain]
  end

  def test_customer_invoice_where_with_array_domain
    stub_odoo("account.move", "search_read", response: [])

    Rodoo::CustomerInvoice.where([["state", "=", "posted"]])

    domain = last_request_body[:domain]
    assert_equal ["move_type", "=", "out_invoice"], domain.first
    assert_includes domain, ["state", "=", "posted"]
  end

  def test_customer_invoice_where_with_keyword_args
    stub_odoo("account.move", "search_read", response: [])

    Rodoo::CustomerInvoice.where(state: "posted")

    domain = last_request_body[:domain]
    assert_equal ["move_type", "=", "out_invoice"], domain.first
    assert_includes domain, ["state", "=", "posted"]
  end

  def test_customer_invoice_where_with_string_condition
    stub_odoo("account.move", "search_read", response: [])

    Rodoo::CustomerInvoice.where("amount_total > 1000")

    domain = last_request_body[:domain]
    assert_equal ["move_type", "=", "out_invoice"], domain.first
    assert_includes domain, ["amount_total", ">", 1000]
  end

  def test_customer_invoice_where_with_empty_conditions
    stub_odoo("account.move", "search_read", response: [])

    Rodoo::CustomerInvoice.where

    domain = last_request_body[:domain]
    assert_equal [["move_type", "=", "out_invoice"]], domain
  end

  def test_provider_invoice_where_prepends_move_type
    stub_odoo("account.move", "search_read", response: [])

    Rodoo::ProviderInvoice.where(state: "draft")

    domain = last_request_body[:domain]
    assert_equal ["move_type", "=", "in_invoice"], domain.first
    assert_includes domain, ["state", "=", "draft"]
  end
end
