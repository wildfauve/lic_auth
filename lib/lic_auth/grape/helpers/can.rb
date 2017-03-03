# frozen_string_literal: true
require "lic_auth/client"

module LicAuth
  module Grape
    module Helpers
      module Can
        def jwt
          env["LIC_AUTH_JWT"]
        end

        def id_token
          env["LIC_AUTH_ID_TOKEN"]
        end

        def can?(user: nil, id_token: nil, app_name:, resource:, action:)
          user_policies = user.try(:policies)

          if user_policies.nil? && id_token
            user_policies = LicAuth::Activities.for_token(id_token).map { |a| a["policy"] }
          end
          LicAuth::Can::Can.new(user_policies).can?(app_name: app_name, resource: resource, action: action)
        end

        def can!(user: nil, id_token: nil, app_name:, resource:, action:)
          unless can?(user: user, id_token: id_token, app_name: app_name, resource: resource, action: action)
            message = "Given token has no permission for action '#{action}', resource: #{resource}, app_name: '#{app_name}'"
            error!(message, 401)
          end
        end
      end
    end
  end
end
