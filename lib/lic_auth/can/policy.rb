# frozen_string_literal: true
module LicAuth::Can
  class Policy
    # policy is a formatted string. Each component of the string is separated by a colon ':'
    # following the following format
    #
    # platform-id:app-id:policy-type
    #
    # Policy types can be defined as follows
    #
    # Policy type 'resource'
    # platform-id:app-id:resource:resource_name:action
    #
    # '*' in any component is a wildcard placeholder
    #
    # examples for policy type: (resource)
    # lic:app_sales_product:resource:product:list
    # lic:app_profiler:resource:profile_entry:create
    # lic:app_sales_product:resource:product:show
    # lic:app_sales_product:resource:product:*
    #
    # Policy Type 'context_resource'
    # ------------------------------
    # lic:app_id:context_resource:resource_name:action
    #
    # A context resource is represents a resource, as well as requiring the user to
    # hold a context assertion for a specific resource.
    # e.g. lic:identity:context_resource:account:update provides access to account
    # updates but is scoped by a specific account identifier
    #
    ATTRIBUTES = [:namespace, :app_name, :policy_type, :resource, :action].freeze
    SUPPORTED_POLICY_TYPES = ["resource", "context_resource"].freeze

    attr_reader *ATTRIBUTES
    attr_reader :errors

    def initialize(policy)
      @policy = policy
      @errors = []
      @all_fields = policy.split(":")
      @namespace, @app_name, @policy_type, @resource, @action = @all_fields
    end

    def valid?
      ATTRIBUTES.each do |attribute|
        @errors << "#{attribute} is blank or missing" if send(attribute).blank?
      end

      unless SUPPORTED_POLICY_TYPES.include?(@policy_type)
        @errors << "policy_type of '#{@policy_type}' is not currently supported"
      end
      @errors.empty?
    end

    def to_s
      @all_fields.join(":")
    end

    def self.find(activities, app_name:, resource:, action:)
      found = activities.detect do |policy|
        policy_match?(policy, app_name: app_name, resource: resource, action: action)
      end
      !!found
    end

    private

    def self.policy_match?(authorized_policy, app_name:, resource:, action:)
      component_match?(authorized_policy.app_name, app_name) &&
      component_match?(authorized_policy.resource, resource) &&
      component_match?(authorized_policy.action, action)
    end

    def self.component_match?(authorized, requested)
      !requested.present? || authorized == "*" || authorized == requested
    end
  end
end
