module LicAuth
  module Util
    class Can
      def self.can?(user: nil, id_token: nil, app_name:, resource:, action:)
        user_policies = user.try(:policies)

        if user_policies.nil? && id_token
          user_policies = LicAuth::Userinfo.for_token(id_token)["allowed_activities"]
        end

        LicAuth::Can::Can.new(user_policies).can?(app_name: app_name, resource: resource, action: action)
      end

      def self.can!(user: nil, id_token: nil, app_name:, resource:, action:)
        unless can?(user: user, id_token: id_token, app_name: app_name, resource: resource, action: action)
          raise LicAuth::Can::Unauthorized.new("Given token has no permission for action '#{action}', resource: #{resource}, app_name: '#{app_name}'")
        end
      end
    end
  end
end
