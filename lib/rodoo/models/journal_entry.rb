# frozen_string_literal: true

module Rodoo
  # Journal entry (move_type: entry)
  #
  # @example
  #   entry = Rodoo::JournalEntry.create(journal_id: 1)
  #   entries = Rodoo::JournalEntry.where([["state", "=", "posted"]])
  #
  class JournalEntry < AccountingEntry
    def self.default_move_type
      "entry"
    end
  end
end
