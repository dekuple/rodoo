# frozen_string_literal: true

module Rodoo
  # Product model for Odoo's product.product (product variants)
  #
  # @example Find a product
  #   product = Rodoo::Product.find(42)
  #
  # @example Search for active products
  #   products = Rodoo::Product.where([["active", "=", true]])
  #
  # @example Create a product
  #   product = Rodoo::Product.create(name: "Widget", list_price: 9.99)
  #
  class Product < Model
    model_name "product.product"
  end
end
