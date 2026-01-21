# frozen_string_literal: true

require "test_helper"
require "base64"
require "tempfile"
require "stringio"

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

  # === Language support ===

  def test_accounting_entry_where_with_lang_passes_context
    stub_odoo("account.move", "search_read", response: [])

    Rodoo::AccountingEntry.where(state: "posted", lang: "es_ES")

    assert_equal({ lang: "es_ES" }, last_request_body[:context])
  end

  def test_customer_invoice_where_with_lang_passes_context
    stub_odoo("account.move", "search_read", response: [])

    Rodoo::CustomerInvoice.where(state: "posted", lang: "fr_FR")

    assert_equal({ lang: "fr_FR" }, last_request_body[:context])
    # Also verify move_type is still prepended
    assert_equal ["move_type", "=", "out_invoice"], last_request_body[:domain].first
  end

  def test_provider_invoice_create_with_lang_passes_context
    stub_odoo("account.move", "create", response: [123])
    stub_odoo("account.move", "read", response: [{ id: 123, move_type: "in_invoice" }])

    Rodoo::ProviderInvoice.create({ partner_id: 42 }, lang: "de_DE")

    # Verify context is passed to create
    create_request = request_bodies.first
    assert_equal({ lang: "de_DE" }, create_request[:context])
    # Verify move_type is still set
    assert_equal "in_invoice", create_request[:vals_list].first[:move_type]
  end

  def test_accounting_entry_where_without_lang_omits_context
    stub_odoo("account.move", "search_read", response: [])

    Rodoo::AccountingEntry.where(state: "posted")

    refute_includes last_request_body.keys, :context
  end

  # Attachment tests

  def test_attach_pdf_from_file_path
    stub_odoo("ir.attachment", "create", response: [100])
    stub_odoo("ir.attachment", "read", response: [{ id: 100, name: "invoice.pdf" }])
    stub_odoo("account.move", "write", response: true)

    invoice = Rodoo::ProviderInvoice.new(id: 42)
    pdf_content = "PDF content"

    Tempfile.create(["test", ".pdf"]) do |file|
      file.binmode
      file.write(pdf_content)
      file.flush

      attachment = invoice.attach_pdf(file.path)

      assert_equal 100, attachment.id
    end

    # Verify attachment creation
    create_request = request_bodies.first
    assert_equal "application/pdf", create_request[:vals_list].first[:mimetype]
    assert_equal "account.move", create_request[:vals_list].first[:res_model]
    assert_equal 42, create_request[:vals_list].first[:res_id]

    # Verify main attachment was set
    write_request = request_bodies.last
    assert_equal [42], write_request[:ids]
    assert_equal 100, write_request[:vals][:message_main_attachment_id]
  end

  def test_attach_pdf_with_custom_filename
    stub_odoo("ir.attachment", "create", response: [101])
    stub_odoo("ir.attachment", "read", response: [{ id: 101, name: "custom.pdf" }])
    stub_odoo("account.move", "write", response: true)

    invoice = Rodoo::ProviderInvoice.new(id: 42)

    Tempfile.create(["original", ".pdf"]) do |file|
      file.binmode
      file.write("PDF content")
      file.flush

      invoice.attach_pdf(file.path, filename: "custom.pdf")
    end

    create_request = request_bodies.first
    assert_equal "custom.pdf", create_request[:vals_list].first[:name]
  end

  def test_attach_pdf_without_setting_as_main
    stub_odoo("ir.attachment", "create", response: [102])

    invoice = Rodoo::ProviderInvoice.new(id: 42)

    Tempfile.create(["test", ".pdf"]) do |file|
      file.binmode
      file.write("PDF content")
      file.flush

      invoice.attach_pdf(file.path, set_as_main: false)
    end

    # Only 1 request: create (no read, no write for main attachment)
    assert_equal 1, request_bodies.size
  end

  def test_attach_pdf_from_io
    stub_odoo("ir.attachment", "create", response: [103])
    stub_odoo("ir.attachment", "read", response: [{ id: 103, name: "io.pdf" }])
    stub_odoo("account.move", "write", response: true)

    invoice = Rodoo::ProviderInvoice.new(id: 42)
    io = StringIO.new("PDF content")

    invoice.attach_pdf(io, filename: "io.pdf")

    create_request = request_bodies.first
    assert_equal "io.pdf", create_request[:vals_list].first[:name]
  end

  def test_attach_pdf_from_base64
    stub_odoo("ir.attachment", "create", response: [104])
    stub_odoo("ir.attachment", "read", response: [{ id: 104, name: "base64.pdf" }])
    stub_odoo("account.move", "write", response: true)

    invoice = Rodoo::ProviderInvoice.new(id: 42)
    base64_data = Base64.strict_encode64("PDF content")

    attachment = invoice.attach_pdf_from_base64(base64_data, filename: "base64.pdf")

    assert_equal 104, attachment.id

    create_request = request_bodies.first
    assert_equal "base64.pdf", create_request[:vals_list].first[:name]
    assert_equal base64_data, create_request[:vals_list].first[:datas]
  end

  def test_attach_pdf_from_base64_without_setting_as_main
    stub_odoo("ir.attachment", "create", response: [105])

    invoice = Rodoo::ProviderInvoice.new(id: 42)
    base64_data = Base64.strict_encode64("PDF content")

    invoice.attach_pdf_from_base64(base64_data, filename: "nosave.pdf", set_as_main: false)

    # Only 1 request: create (no read, no write)
    assert_equal 1, request_bodies.size
  end

  def test_set_main_attachment_with_attachment_object
    stub_odoo("account.move", "write", response: true)

    invoice = Rodoo::ProviderInvoice.new(id: 42)
    attachment = Rodoo::Attachment.new(id: 200)

    invoice.set_main_attachment(attachment)

    assert_equal [42], last_request_body[:ids]
    assert_equal 200, last_request_body[:vals][:message_main_attachment_id]
  end

  def test_set_main_attachment_with_id
    stub_odoo("account.move", "write", response: true)

    invoice = Rodoo::ProviderInvoice.new(id: 42)

    invoice.set_main_attachment(300)

    assert_equal [42], last_request_body[:ids]
    assert_equal 300, last_request_body[:vals][:message_main_attachment_id]
  end

  def test_attachments_lists_all
    stub_odoo("ir.attachment", "search_read", response: [
                { id: 1, name: "doc1.pdf" },
                { id: 2, name: "doc2.xml" }
              ])

    invoice = Rodoo::ProviderInvoice.new(id: 42)
    attachments = invoice.attachments

    assert_equal 2, attachments.size
    assert_equal [["res_model", "=", "account.move"], ["res_id", "=", 42]], last_request_body[:domain]
  end

  def test_attachments_with_mimetype_filter
    stub_odoo("ir.attachment", "search_read", response: [{ id: 1, name: "doc.pdf" }])

    invoice = Rodoo::ProviderInvoice.new(id: 42)
    invoice.attachments(mimetype: "application/pdf")

    expected_domain = [
      ["res_model", "=", "account.move"],
      ["res_id", "=", 42],
      ["mimetype", "=", "application/pdf"]
    ]
    assert_equal expected_domain, last_request_body[:domain]
  end

  def test_main_attachment_when_set
    stub_odoo("ir.attachment", "read", response: [{ id: 500, name: "main.pdf" }])

    invoice = Rodoo::ProviderInvoice.new(id: 42, message_main_attachment_id: [500, "main.pdf"])
    main = invoice.main_attachment

    assert_equal 500, main.id
    assert_equal "main.pdf", main.name
  end

  def test_main_attachment_with_integer_id
    stub_odoo("ir.attachment", "read", response: [{ id: 501, name: "main2.pdf" }])

    invoice = Rodoo::ProviderInvoice.new(id: 42, message_main_attachment_id: 501)
    main = invoice.main_attachment

    assert_equal 501, main.id
  end

  def test_main_attachment_when_not_set
    invoice = Rodoo::ProviderInvoice.new(id: 42)
    assert_nil invoice.main_attachment
  end

  def test_main_attachment_when_false
    invoice = Rodoo::ProviderInvoice.new(id: 42, message_main_attachment_id: false)
    assert_nil invoice.main_attachment
  end

  def test_attach_pdf_derives_filename_from_path
    stub_odoo("ir.attachment", "create", response: [106])
    stub_odoo("ir.attachment", "read", response: [{ id: 106, name: "derived.pdf" }])
    stub_odoo("account.move", "write", response: true)

    invoice = Rodoo::ProviderInvoice.new(id: 42)

    Tempfile.create(["derived", ".pdf"]) do |file|
      file.binmode
      file.write("PDF content")
      file.flush

      invoice.attach_pdf(file.path)
    end

    create_request = request_bodies.first
    # The filename should be derived from the tempfile path (will be something like derived20261234.pdf)
    assert create_request[:vals_list].first[:name].end_with?(".pdf")
  end
end
