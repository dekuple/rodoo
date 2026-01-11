# frozen_string_literal: true

module Rodoo
  # Accounting entry line (account.move.line) - individual debit/credit lines within an accounting entry.
  #
  # Every accounting entry (invoice, bill, journal entry) has at least two lines:
  # one for the debit side and one for the credit side.
  #
  # @example Find lines for a specific entry
  #   lines = Rodoo::AccountingEntryLine.where([["move_id", "=", 42]])
  #
  # @example Find all receivable lines
  #   receivables = Rodoo::AccountingEntryLine.where([["account_type", "=", "asset_receivable"]])
  #
  # @example Get line details
  #   line = Rodoo::AccountingEntryLine.find(123)
  #   line.debit    # => 1000.0
  #   line.credit   # => 0.0
  #   line.balance  # => 1000.0
  #
  class AccountingEntryLine < Model
    model_name "account.move.line"
  end
end
