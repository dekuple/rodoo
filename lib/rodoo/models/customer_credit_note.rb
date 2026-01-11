# frozen_string_literal: true

module Rodoo
  # Customer credit note / refund (move_type: out_refund)
  #
  # @example
  #   credit_note = Rodoo::CustomerCreditNote.create(partner_id: 42)
  #   credit_notes = Rodoo::CustomerCreditNote.where([["state", "=", "posted"]])
  #
  class CustomerCreditNote < AccountingEntry
    def self.default_move_type
      "out_refund"
    end
  end
end
