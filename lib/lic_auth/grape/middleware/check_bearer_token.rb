# frozen_string_literal: true
require "lic_auth/util/jwt"

module LicAuth
  module Middleware
    # DEPRECATED: use LicAuth::Rack::CheckBearerToken instead
    module CheckBearerToken
      BEARER_TOKEN_PATTERN = /Bearer\s+(.+)/

      def self.included(base)
        base.rescue_from JSON::JWS::VerificationFailed do |_e|
          error!("urn:lic:authentication:error:jwt_expired", 401)
        end

        base.rescue_from JSON::JWT::InvalidFormat do |_e|
          error!("urn:lic:authentication:error:jwt_invalid_format", 400)
        end

        base.class_eval do
          before do
            auth_header = headers["Authorization"]
            bearer_token = Regexp.last_match(1) if auth_header =~ BEARER_TOKEN_PATTERN
            @id_token = LicAuth::Jwt.decode!(bearer_token)
          end

          helpers do
            attr_reader :id_token
          end
        end
      end
    end
  end
end
