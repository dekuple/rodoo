# frozen_string_literal: true

module Rodoo
  # Contact model for Odoo's res.partner (contacts/companies)
  #
  # @example Find a contact
  #   contact = Rodoo::Contact.find(42)
  #
  # @example Search for companies
  #   companies = Rodoo::Contact.where([["is_company", "=", true]])
  #
  # @example Create a contact
  #   contact = Rodoo::Contact.create(name: "Acme Corp", is_company: true)
  #
  class Contact < Model
    model_name "res.partner"
  end
end
