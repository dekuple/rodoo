# frozen_string_literal: true

module Rodoo
  # Provider/vendor credit note / refund (move_type: in_refund)
  #
  # @example
  #   refund = Rodoo::ProviderCreditNote.create(partner_id: 42)
  #   refunds = Rodoo::ProviderCreditNote.where([["state", "=", "posted"]])
  #
  class ProviderCreditNote < AccountingEntry
    def self.default_move_type
      "in_refund"
    end
  end
end
