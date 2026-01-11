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
  class AccountingEntry < Model
    model_name "account.move"

    # Subclasses override this to specify their move_type
    #
    # @return [String, nil] The move_type value for this class
    def self.default_move_type
      nil
    end

    # Search for records, automatically scoped to the move_type
    #
    # @param conditions [Array, Hash, String, nil] Query conditions
    # @param options [Hash] Additional options (fields, limit, offset)
    # @return [Array<AccountingEntry>] Array of matching records
    def self.where(conditions = nil, **options)
      domain = DomainBuilder.build(conditions, options.except(:fields, :limit, :offset))
      domain = [["move_type", "=", default_move_type]] + domain if default_move_type
      super(domain, **options.slice(:fields, :limit, :offset))
    end

    # Create a new record, automatically setting the move_type
    #
    # @param attrs [Hash] Attributes for the new record
    # @return [AccountingEntry] The created record
    def self.create(attrs)
      scoped_attrs = if default_move_type
                       { move_type: default_move_type }.merge(attrs)
                     else
                       attrs
                     end
      super(scoped_attrs)
    end
  end
end
