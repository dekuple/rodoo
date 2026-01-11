# frozen_string_literal: true

module Rodoo
  # Provider/vendor invoice (move_type: in_invoice)
  #
  # @example
  #   bill = Rodoo::ProviderInvoice.create(partner_id: 42)
  #   bills = Rodoo::ProviderInvoice.where([["state", "=", "posted"]])
  #
  class ProviderInvoice < AccountingEntry
    def self.default_move_type
      "in_invoice"
    end
  end
end
