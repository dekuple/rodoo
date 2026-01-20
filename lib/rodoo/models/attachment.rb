# frozen_string_literal: true

require "base64"

module Rodoo
  # Wrapper for Odoo's ir.attachment model.
  #
  # Provides methods for creating and querying file attachments linked to Odoo records.
  #
  # @example Create an attachment from a file path
  #   invoice = Rodoo::ProviderInvoice.find(42)
  #   Rodoo::Attachment.create_for(
  #     invoice, "/path/to/file.pdf", filename: "invoice.pdf", mimetype: "application/pdf"
  #   )
  #
  # @example Create an attachment from base64 data
  #   Rodoo::Attachment.create_from_base64(
  #     invoice, base64_data, filename: "doc.pdf", mimetype: "application/pdf"
  #   )
  #
  # @example List attachments for a record
  #   Rodoo::Attachment.for_record(invoice)
  #   Rodoo::Attachment.for_record(invoice, mimetype: "application/pdf")
  #
  class Attachment < Model
    model_name "ir.attachment"

    # Create an attachment for a record from a file path or IO object
    #
    # @param record [Model] The Odoo record to attach the file to
    # @param file_path_or_io [String, IO, #read] File path or IO-like object
    # @param filename [String] The filename for the attachment
    # @param mimetype [String] The MIME type of the file
    # @return [Attachment] The created attachment
    #
    # @example From file path
    #   Rodoo::Attachment.create_for(
    #     invoice, "/path/to/file.pdf", filename: "invoice.pdf", mimetype: "application/pdf"
    #   )
    #
    # @example From IO object
    #   File.open("/path/to/file.pdf", "rb") do |f|
    #     Rodoo::Attachment.create_for(
    #       invoice, f, filename: "invoice.pdf", mimetype: "application/pdf"
    #     )
    #   end
    #
    def self.create_for(record, file_path_or_io, filename:, mimetype:)
      data = read_file_data(file_path_or_io)
      base64_data = Base64.strict_encode64(data)
      create_from_base64(record, base64_data, filename: filename, mimetype: mimetype)
    end

    # Create an attachment for a record from base64-encoded data
    #
    # @param record [Model] The Odoo record to attach the file to
    # @param base64_data [String] The base64-encoded file data
    # @param filename [String] The filename for the attachment
    # @param mimetype [String] The MIME type of the file
    # @return [Attachment] The created attachment
    #
    # @example
    #   Rodoo::Attachment.create_from_base64(
    #     invoice, base64_content, filename: "doc.pdf", mimetype: "application/pdf"
    #   )
    #
    def self.create_from_base64(record, base64_data, filename:, mimetype:)
      attrs = {
        name: filename,
        type: "binary",
        datas: base64_data,
        res_model: record.class.model_name,
        res_id: record.id,
        mimetype: mimetype
      }
      ids = execute("create", vals_list: [attrs])
      # Don't call find() - reading ir.attachment fails when Odoo tries to return
      # the binary datas field. Return an instance with the known attributes.
      new(attrs.except(:datas).merge(id: ids.first))
    end

    # Find all attachments for a record
    #
    # @param record [Model] The Odoo record to find attachments for
    # @param mimetype [String, nil] Optional MIME type filter
    # @return [Array<Attachment>] Array of attachments
    #
    # @example Get all attachments
    #   Rodoo::Attachment.for_record(invoice)
    #
    # @example Get only PDF attachments
    #   Rodoo::Attachment.for_record(invoice, mimetype: "application/pdf")
    #
    def self.for_record(record, mimetype: nil)
      domain = [
        ["res_model", "=", record.class.model_name],
        ["res_id", "=", record.id]
      ]
      domain << ["mimetype", "=", mimetype] if mimetype
      where(domain)
    end

    # Read file data from a path or IO object
    #
    # @param file_path_or_io [String, IO, #read] File path or IO-like object
    # @return [String] Binary file data
    # @api private
    def self.read_file_data(file_path_or_io)
      if file_path_or_io.respond_to?(:read)
        file_path_or_io.read
      else
        File.binread(file_path_or_io)
      end
    end
    private_class_method :read_file_data
  end
end
