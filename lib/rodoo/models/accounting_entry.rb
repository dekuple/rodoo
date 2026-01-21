# frozen_string_literal: true

module Rodoo
  # Base class for Odoo accounting entries (account.move).
  #
  # In Odoo, customer invoices, provider invoices, credit notes, and journal entries
  # are all stored in the same model (account.move) and differentiated by the move_type field.
  #
  # This class provides the base functionality, while subclasses automatically filter
  # and set the appropriate move_type.
  #
  # @example Using a specific subclass
  #   invoice = Rodoo::CustomerInvoice.create(partner_id: 42)
  #   bills = Rodoo::ProviderInvoice.where([["state", "=", "posted"]])
  #
  # @example Using the base class to query all types
  #   all_entries = Rodoo::AccountingEntry.where([["date", ">", "2025-01-01"]])
  #
  # @example Attaching a PDF
  #   invoice = Rodoo::ProviderInvoice.find(42)
  #   invoice.attach_pdf("/path/to/invoice.pdf")
  #
  class AccountingEntry < Model
    model_name "account.move"

    PDF_MIMETYPE = "application/pdf"
    private_constant :PDF_MIMETYPE

    # Subclasses override this to specify their move_type
    #
    # @return [String, nil] The move_type value for this class
    def self.default_move_type
      nil
    end

    # Search for records, automatically scoped to the move_type
    #
    # @param conditions [Array, Hash, String, nil] Query conditions
    # @param options [Hash] Additional options (fields, limit, offset, lang)
    # @return [Array<AccountingEntry>] Array of matching records
    def self.where(conditions = nil, **options)
      domain = DomainBuilder.build(conditions, options.except(:fields, :limit, :offset, :lang))
      domain = [["move_type", "=", default_move_type]] + domain if default_move_type
      super(domain, **options.slice(:fields, :limit, :offset, :lang))
    end

    # Create a new record, automatically setting the move_type
    #
    # @param attrs [Hash] Attributes for the new record
    # @param lang [String, nil] Language code for translatable fields
    # @return [AccountingEntry] The created record
    def self.create(attrs = nil, lang: nil, **kwargs)
      actual_attrs = attrs || kwargs
      scoped_attrs = if default_move_type
                       { move_type: default_move_type }.merge(actual_attrs)
                     else
                       actual_attrs
                     end
      super(scoped_attrs, lang: lang)
    end

    # Attach a PDF file to this record
    #
    # @param file_path_or_io [String, IO, #read] File path or IO-like object
    # @param filename [String, nil] The filename (derived from path if not provided)
    # @param set_as_main [Boolean] Whether to set this as the main attachment (default: true)
    # @return [Attachment] The created attachment
    #
    # @example Attach from file path (sets as main by default)
    #   invoice.attach_pdf("/path/to/invoice.pdf")
    #
    # @example Attach without setting as main
    #   invoice.attach_pdf("/path/to/supporting.pdf", set_as_main: false)
    #
    def attach_pdf(file_path_or_io, filename: nil, set_as_main: true)
      resolved_filename = filename || derive_filename(file_path_or_io)
      attachment = Attachment.create_for(
        self, file_path_or_io, filename: resolved_filename, mimetype: PDF_MIMETYPE
      )
      set_main_attachment(attachment) if set_as_main
      attachment
    end

    # Attach a PDF from base64-encoded data
    #
    # @param base64_data [String] The base64-encoded PDF data
    # @param filename [String] The filename for the attachment
    # @param set_as_main [Boolean] Whether to set this as the main attachment (default: true)
    # @return [Attachment] The created attachment
    #
    # @example
    #   invoice.attach_pdf_from_base64(base64_content, filename: "invoice.pdf")
    #
    def attach_pdf_from_base64(base64_data, filename:, set_as_main: true)
      attachment = Attachment.create_from_base64(
        self, base64_data, filename: filename, mimetype: PDF_MIMETYPE
      )
      set_main_attachment(attachment) if set_as_main
      attachment
    end

    # Set the main attachment for this record (visible in Odoo's side panel)
    #
    # @param attachment_or_id [Attachment, Integer] The attachment or its ID
    # @return [self]
    #
    # @example With an Attachment object
    #   invoice.set_main_attachment(attachment)
    #
    # @example With an attachment ID
    #   invoice.set_main_attachment(123)
    #
    # rubocop:disable Naming/AccessorMethodName
    def set_main_attachment(attachment_or_id)
      attachment_id = attachment_or_id.is_a?(Attachment) ? attachment_or_id.id : attachment_or_id
      update(message_main_attachment_id: attachment_id)
    end
    # rubocop:enable Naming/AccessorMethodName

    # List attachments for this record
    #
    # @param mimetype [String, nil] Optional MIME type filter
    # @return [Array<Attachment>] Array of attachments
    #
    # @example Get all attachments
    #   invoice.attachments
    #
    # @example Get only PDF attachments
    #   invoice.attachments(mimetype: "application/pdf")
    #
    def attachments(mimetype: nil)
      Attachment.for_record(self, mimetype: mimetype)
    end

    # Get the main attachment for this record
    #
    # @return [Attachment, nil] The main attachment or nil if not set
    #
    # @example
    #   main = invoice.main_attachment
    #
    def main_attachment
      main_id = self[:message_main_attachment_id]
      return nil unless main_id

      # Odoo returns [id, name] for many2one fields
      attachment_id = main_id.is_a?(Array) ? main_id.first : main_id
      return nil unless attachment_id

      Attachment.find(attachment_id)
    end

    private

    def derive_filename(file_path_or_io)
      if file_path_or_io.respond_to?(:path)
        File.basename(file_path_or_io.path)
      elsif file_path_or_io.is_a?(String)
        File.basename(file_path_or_io)
      else
        "attachment.pdf"
      end
    end
  end
end
