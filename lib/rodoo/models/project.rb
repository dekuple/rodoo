# frozen_string_literal: true

module Rodoo
  # Project model for Odoo's project.project table.
  #
  # @example Find a project by ID
  #   project = Rodoo::Project.find(42)
  #
  # @example Search for projects
  #   project = Rodoo::Project.where([["is_company", "=", true]])
  #
  # @example Create a project
  #   project = Rodoo::Project.create(name: "my_project", account_id: analytic_account_id, allow_billable: true)
  #
  class Project < Model
    model_name "project.project"
  end
end
