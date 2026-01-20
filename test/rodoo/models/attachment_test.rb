# frozen_string_literal: true

require "test_helper"
require "base64"
require "tempfile"
require "stringio"

class AttachmentTest < RodooTestCase
  def test_model_name
    assert_equal "ir.attachment", Rodoo::Attachment.model_name
  end

  def test_inherits_from_model
    assert Rodoo::Attachment < Rodoo::Model
  end

  def test_create_from_base64
    stub_odoo("ir.attachment", "create", response: [100])
    stub_odoo("ir.attachment", "read", response: [{ id: 100, name: "test.pdf" }])

    record = mock_record("res.partner", 42)
    base64_data = Base64.strict_encode64("PDF content")

    attachment = Rodoo::Attachment.create_from_base64(
      record,
      base64_data,
      filename: "test.pdf",
      mimetype: "application/pdf"
    )

    assert_equal 100, attachment.id

    create_request = request_bodies.first
    assert_equal "test.pdf", create_request[:vals_list].first[:name]
    assert_equal base64_data, create_request[:vals_list].first[:datas]
    assert_equal "res.partner", create_request[:vals_list].first[:res_model]
    assert_equal 42, create_request[:vals_list].first[:res_id]
    assert_equal "application/pdf", create_request[:vals_list].first[:mimetype]
  end

  def test_create_for_with_file_path
    stub_odoo("ir.attachment", "create", response: [101])
    stub_odoo("ir.attachment", "read", response: [{ id: 101, name: "document.pdf" }])

    record = mock_record("res.partner", 42)
    pdf_content = "PDF binary content"

    Tempfile.create(["test", ".pdf"]) do |file|
      file.binmode
      file.write(pdf_content)
      file.flush

      Rodoo::Attachment.create_for(
        record,
        file.path,
        filename: "document.pdf",
        mimetype: "application/pdf"
      )
    end

    create_request = request_bodies.first
    assert_equal "document.pdf", create_request[:vals_list].first[:name]
    assert_equal Base64.strict_encode64(pdf_content), create_request[:vals_list].first[:datas]
  end

  def test_create_for_with_io_object
    stub_odoo("ir.attachment", "create", response: [102])
    stub_odoo("ir.attachment", "read", response: [{ id: 102, name: "io_doc.pdf" }])

    record = mock_record("res.partner", 42)
    pdf_content = "IO PDF content"
    io = StringIO.new(pdf_content)

    Rodoo::Attachment.create_for(
      record,
      io,
      filename: "io_doc.pdf",
      mimetype: "application/pdf"
    )

    create_request = request_bodies.first
    assert_equal "io_doc.pdf", create_request[:vals_list].first[:name]
    assert_equal Base64.strict_encode64(pdf_content), create_request[:vals_list].first[:datas]
  end

  def test_for_record_without_mimetype_filter
    stub_odoo("ir.attachment", "search_read", response: [
                { id: 1, name: "doc1.pdf" },
                { id: 2, name: "doc2.xml" }
              ])

    record = mock_record("account.move", 42)
    attachments = Rodoo::Attachment.for_record(record)

    assert_equal 2, attachments.size
    assert_equal [["res_model", "=", "account.move"], ["res_id", "=", 42]], last_request_body[:domain]
  end

  def test_for_record_with_mimetype_filter
    stub_odoo("ir.attachment", "search_read", response: [{ id: 1, name: "doc.pdf" }])

    record = mock_record("account.move", 42)
    Rodoo::Attachment.for_record(record, mimetype: "application/pdf")

    expected_domain = [
      ["res_model", "=", "account.move"],
      ["res_id", "=", 42],
      ["mimetype", "=", "application/pdf"]
    ]
    assert_equal expected_domain, last_request_body[:domain]
  end

  private

  def mock_record(model_name, id)
    klass = Class.new(Rodoo::Model) do
      model_name model_name
    end
    # Need to set the model_name properly since Ruby doesn't allow dynamic constants
    klass.define_singleton_method(:model_name) { model_name }
    klass.new(id: id)
  end
end
