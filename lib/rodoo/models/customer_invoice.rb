# frozen_string_literal: true

module Rodoo
  # Customer invoice (move_type: out_invoice)
  #
  # @example
  #   invoice = Rodoo::CustomerInvoice.create(partner_id: 42)
  #   invoices = Rodoo::CustomerInvoice.where([["state", "=", "posted"]])
  #
  class CustomerInvoice < AccountingEntry
    def self.default_move_type
      "out_invoice"
    end
  end
end
