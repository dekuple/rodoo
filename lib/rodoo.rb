# frozen_string_literal: true

require_relative "rodoo/version"
require_relative "rodoo/configuration"
require_relative "rodoo/connection"
require_relative "rodoo/errors"
require_relative "rodoo/domain_builder"
require_relative "rodoo/model"

module Rodoo
  autoload :Account, "rodoo/models/account"
  autoload :AccountingEntry, "rodoo/models/accounting_entry"
  autoload :AccountingEntryLine, "rodoo/models/accounting_entry_line"
  autoload :AnalyticAccount, "rodoo/models/analytic_account"
  autoload :AnalyticPlan, "rodoo/models/analytic_plan"
  autoload :Attachment, "rodoo/models/attachment"
  autoload :CustomerCreditNote, "rodoo/models/customer_credit_note"
  autoload :CustomerInvoice, "rodoo/models/customer_invoice"
  autoload :Journal, "rodoo/models/journal"
  autoload :JournalEntry, "rodoo/models/journal_entry"
  autoload :Contact, "rodoo/models/contact"
  autoload :Product, "rodoo/models/product"
  autoload :Project, "rodoo/models/project"
  autoload :ProviderCreditNote, "rodoo/models/provider_credit_note"
  autoload :ProviderInvoice, "rodoo/models/provider_invoice"
  autoload :Tax, "rodoo/models/tax"

  @configuration = nil
  @connection = nil

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
    @connection = nil # Reset connection when configuration changes
  end

  def self.reset!
    @configuration = Configuration.new
    @connection = nil
  end

  def self.connection
    configuration.validate!
    @connection ||= Connection.new(configuration)
  end
end
