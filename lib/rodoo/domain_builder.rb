# frozen_string_literal: true

module Rodoo
  # Converts various condition formats into Odoo domain arrays.
  #
  # Supports:
  # - Hash: equality conditions `{ name: "John" }` → `[["name", "=", "John"]]`
  # - String: parsed condition `"age > 18"` → `[["age", ">", 18]]`
  # - Array of strings: `["age > 18", "active = true"]`
  # - Array of arrays: raw Odoo domain (passthrough)
  #
  module DomainBuilder
    CONDITION_PATTERN = /\A(\w+)\s*(=|!=|<>|<=|>=|<|>|like|ilike|=like|=ilike)\s*(.+)\z/i

    module_function

    def build(conditions, attrs = {})
      return hash_to_domain(attrs) if attrs.any?
      return [] if conditions.nil?

      case conditions
      when String then [parse_string_condition(conditions)]
      when Hash then hash_to_domain(conditions)
      when Array then array_to_domain(conditions)
      else raise ArgumentError, "Invalid conditions: #{conditions.class}"
      end
    end

    def hash_to_domain(hash)
      hash.map { |k, v| [k.to_s, "=", v] }
    end

    def array_to_domain(arr)
      return [] if arr.empty?
      return arr.map { |s| parse_string_condition(s) } if arr.first.is_a?(String)

      arr
    end

    def parse_string_condition(str)
      match = str.strip.match(CONDITION_PATTERN)
      raise ArgumentError, "Invalid condition: '#{str}'" unless match

      field = match[1]
      operator = match[2] == "<>" ? "!=" : match[2].downcase
      value = parse_value(match[3].strip)

      [field, operator, value]
    end

    def parse_value(str)
      case str
      when /\A["'](.*)["']\z/ then ::Regexp.last_match(1)
      when /\Atrue\z/i then true
      when /\Afalse\z/i then false
      when /\A-?\d+\z/ then str.to_i
      when /\A-?\d+\.\d+\z/ then str.to_f
      else str
      end
    end
  end
end
