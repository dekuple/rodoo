# frozen_string_literal: true

module Rodoo
  # Base class for Odoo models. Provides both class-level query methods and instance-level persistence.
  #
  # @example Defining a model
  #   class Contact < Rodoo::Model
  #     model_name "res.partner"
  #   end
  #
  # @example Querying
  #   contact = Rodoo::Contact.find(42)
  #   contacts = Rodoo::Contact.where([["is_company", "=", true]])
  #   all = Rodoo::Contact.all(limit: 10)
  #
  # @example Creating
  #   contact = Rodoo::Contact.create(name: "Acme Corp")
  #
  # @example Building and saving
  #   contact = Rodoo::Contact.new(name: "Draft")
  #   contact.email = "draft@example.com"
  #   contact.save
  #
  class Model # rubocop:disable Metrics/ClassLength
    # ============================================
    # Class-level configuration and query methods
    # ============================================

    # Sets or gets the Odoo model name for this model
    #
    # @param name [String, nil] The Odoo model name (e.g., "res.partner")
    # @return [String] The model name
    def self.model_name(name = nil)
      if name
        @odoo_model_name = name
      else
        @odoo_model_name || (superclass.respond_to?(:model_name) ? superclass.model_name : nil)
      end
    end

    # Find a single record by ID
    #
    # @param id [Integer] The record ID
    # @return [Model] The found record
    # @raise [Rodoo::NotFoundError] If the record doesn't exist
    #
    # @example
    #   contact = Rodoo::Contact.find(42)
    #   contact.name  # => "Acme Corp"
    #
    # @example With language
    #   contact = Rodoo::Contact.find(42, lang: "fr_FR")
    #
    def self.find(id, lang: nil)
      params = { ids: [id] }
      params[:context] = { lang: lang } if lang
      result = execute("read", params)
      raise NotFoundError, "#{model_name} with id=#{id} not found" if result.nil? || result.empty?

      new(result.first)
    end

    # Search for records with flexible query syntax
    #
    # @param conditions [Array, Hash, String, nil] Query conditions
    # @param fields [Array<String>, nil] Fields to retrieve
    # @param limit [Integer, nil] Maximum records to return
    # @param offset [Integer, nil] Number of records to skip
    # @return [Array<Model>] Array of matching records
    #
    # @example Keyword arguments (equality)
    #   Rodoo::Contact.where(name: "Acme", is_company: true)
    #
    # @example String condition
    #   Rodoo::Contact.where("credit_limit > 1000")
    #
    # @example Array of strings
    #   Rodoo::Contact.where(["credit_limit > 1000", "active = true"])
    #
    # @example Raw Odoo domain (array of arrays)
    #   Rodoo::Contact.where([["is_company", "=", true]], limit: 10)
    #
    # @example With language
    #   Rodoo::Contact.where(is_company: true, lang: "es_ES")
    #
    # rubocop:disable Metrics/ParameterLists
    def self.where(conditions = nil, fields: nil, limit: nil, offset: nil, lang: nil, **attrs)
      # rubocop:enable Metrics/ParameterLists
      domain = DomainBuilder.build(conditions, attrs)

      params = { domain: domain }
      params[:fields] = fields if fields
      params[:limit] = limit if limit
      params[:offset] = offset if offset
      params[:context] = { lang: lang } if lang

      execute("search_read", params).map { |record| new(record) }
    end

    # Fetch all records (optionally limited)
    #
    # @param fields [Array<String>, nil] Fields to retrieve
    # @param limit [Integer, nil] Maximum records to return
    # @return [Array<Model>] Array of records
    #
    # @example
    #   all_contacts = Rodoo::Contact.all(limit: 100)
    #
    # @example With language
    #   all_contacts = Rodoo::Contact.all(limit: 100, lang: "de_DE")
    #
    def self.all(fields: nil, limit: nil, lang: nil)
      where([], fields: fields, limit: limit, lang: lang)
    end

    # Find a single record by attribute conditions
    #
    # @param conditions [Array, Hash, String, nil] Query conditions (same as where)
    # @return [Model, nil] The first matching record or nil if not found
    #
    # @example Find by keyword arguments
    #   contact = Rodoo::Contact.find_by(email: "john@example.com")
    #
    # @example Find by multiple conditions
    #   contact = Rodoo::Contact.find_by(name: "Acme Corp", is_company: true)
    #
    # @example Find by string condition
    #   contact = Rodoo::Contact.find_by("credit_limit > 1000")
    #
    # @example Find by raw domain
    #   contact = Rodoo::Contact.find_by([["name", "ilike", "%acme%"]])
    #
    # @example With language
    #   contact = Rodoo::Contact.find_by(name: "Acme", lang: "fr_FR")
    #
    def self.find_by(conditions = nil, lang: nil, **attrs)
      where(conditions, limit: 1, lang: lang, **attrs).first
    end

    # Find a single record by attribute conditions, raising if not found
    #
    # @param conditions [Array, Hash, String, nil] Query conditions (same as where)
    # @return [Model] The first matching record
    # @raise [Rodoo::NotFoundError] If no matching record is found
    #
    # @example Find by email (raises if not found)
    #   contact = Rodoo::Contact.find_by!(email: "john@example.com")
    #
    # @example With language
    #   contact = Rodoo::Contact.find_by!(email: "john@example.com", lang: "it_IT")
    #
    def self.find_by!(conditions = nil, lang: nil, **attrs)
      record = find_by(conditions, lang: lang, **attrs)
      return record if record

      raise NotFoundError, "#{model_name} matching #{conditions.inspect} #{attrs.inspect} not found"
    end

    # Create a new record in Odoo
    #
    # @param attrs [Hash] Attributes for the new record
    # @return [Model] The created record with its ID
    #
    # @example
    #   contact = Rodoo::Contact.create(name: "New Contact", email: "new@example.com")
    #   contact.id  # => 123
    #
    # @example With language
    #   contact = Rodoo::Contact.create({ name: "Nouveau Contact" }, lang: "fr_FR")
    #
    def self.create(attrs = nil, lang: nil, **kwargs)
      actual_attrs = attrs || kwargs
      params = { vals_list: [actual_attrs] }
      params[:context] = { lang: lang } if lang
      ids = execute("create", params)
      find(ids.first, lang: lang)
    end

    # Execute an Odoo method via the JSON-2 API
    #
    # @param method [String] The method to call (e.g., "search_read")
    # @param params [Hash] The method parameters
    # @return [Object] The response data
    def self.execute(method, params = {})
      Rodoo.connection.execute(model_name, method, params)
    end

    # ============================================
    # Instance attributes and lifecycle
    # ============================================

    def initialize(attributes = {})
      @attributes = (attributes || {}).transform_keys(&:to_sym)
    end

    def [](key)
      @attributes[key.to_sym]
    end

    def []=(key, value)
      @attributes[key.to_sym] = value
    end

    def to_h
      @attributes.dup
    end

    def persisted?
      !id.nil?
    end

    # Save the record to Odoo
    #
    # Creates a new record if unpersisted, updates if persisted.
    #
    # @return [self]
    def save
      if persisted?
        update(to_h.except(:id))
      else
        result = self.class.create(to_h)
        self.id = result.id
      end
      self
    end

    # Update specific attributes on a persisted record
    #
    # @param attrs [Hash] Attributes to update
    # @return [self]
    # @raise [Rodoo::Error] If the record hasn't been persisted
    def update(attrs)
      raise Error, "Cannot update a record that hasn't been persisted" unless persisted?

      normalized = attrs.transform_keys(&:to_sym)
      self.class.execute("write", ids: [id], vals: normalized)
      normalized.each { |key, value| self[key] = value }
      self
    end

    # Reload the record from Odoo
    #
    # @return [self]
    # @raise [Rodoo::Error] If the record hasn't been persisted
    def reload
      raise Error, "Cannot reload a record that hasn't been persisted" unless persisted?

      fresh = self.class.find(id)
      fresh.to_h.each { |key, value| self[key] = value }
      self
    end

    # Permanently delete the record from Odoo
    #
    # @return [self] The deleted record (frozen)
    # @raise [Rodoo::Error] If the record hasn't been persisted
    #
    # @example
    #   contact = Rodoo::Contact.find(42)
    #   contact.destroy
    #   contact.destroyed?  # => true
    #
    def destroy
      raise Error, "Cannot destroy a record that hasn't been persisted" unless persisted?

      self.class.execute("unlink", ids: [id])
      @destroyed = true
      freeze
    end

    # Check if this record has been destroyed
    #
    # @return [Boolean]
    def destroyed?
      @destroyed == true
    end

    # Posts a message to the record's chatter (mail thread).
    # This is used for internal notes, comments, and notifications in Odoo.
    #
    # @param body [String] HTML content of the message
    # @param message_type [String] Type: "comment", "notification", "email", "user_notification"
    # @param subtype_xmlid [String, nil] XML ID for subtype (e.g., "mail.mt_note" for internal notes)
    # @param kwargs [Hash] Additional parameters to pass to message_post
    # @return [Integer] The ID of the created mail.message record
    # @raise [Rodoo::Error] If the record hasn't been persisted
    #
    # @example Post an internal note
    #   invoice.message_post(
    #     body: "<p>This is an internal note</p>",
    #     message_type: "comment",
    #     subtype_xmlid: "mail.mt_note"
    #   )
    #
    def message_post(body:, message_type: "comment", subtype_xmlid: nil, **kwargs)
      raise Error, "Cannot post message to a record that hasn't been persisted" unless persisted?

      params = {
        ids: [id],
        body: body,
        message_type: message_type,
        subtype_xmlid: subtype_xmlid,
        **kwargs
      }.compact

      self.class.execute("message_post", params)
    end

    def inspect
      "#<#{self.class.name} id=#{id.inspect} #{inspectable_attributes}>"
    end

    private

    def respond_to_missing?(_method_name, _include_private = false)
      true
    end

    def method_missing(method_name, *args, &)
      attr_name = method_name.to_s

      if attr_name.end_with?("=")
        @attributes[attr_name.delete_suffix("=").to_sym] = args.first
      else
        @attributes[method_name]
      end
    end

    def inspectable_attributes
      to_h.except(:id).map { |k, v| "#{k}=#{v.inspect}" }.join(" ")
    end
  end
end
