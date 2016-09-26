# frozen_string_literal: true
require "multi_json"
require "lic_auth/util/jwt"

module LicAuth
  module Rack
    class CheckBearerToken
      ENV_REQUEST_METHOD      = "REQUEST_METHOD".freeze
      ENV_AUTHORIZATION       = "HTTP_AUTHORIZATION".freeze
      ENV_TOKEN               = "FLICK_AUTH_ID_TOKEN".freeze
      ENV_JWT                 = "FLICK_AUTH_JWT".freeze
      URN_NOT_PRESENT         = "urn:lic:authentication:error:token_not_present".freeze
      URN_INVALID_FORMAT      = "urn:lic:authentication:error:token_invalid_format".freeze
      URN_VERIFICATION_FAILED = "urn:lic:authentication:error:token_verification_failed".freeze
      BEARER_TOKEN_PATTERN    = /\ABearer\s+(?<bearer_token>.+)\z/
      METHOD_OPTIONS          = "OPTIONS".freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless authorisation_required?(env)

        return not_present unless env[ENV_AUTHORIZATION]

        match = BEARER_TOKEN_PATTERN.match(env[ENV_AUTHORIZATION])

        env[ENV_JWT] = if match
                         match[:bearer_token]
                       else
                         env[ENV_AUTHORIZATION]
        end

        env[ENV_TOKEN] = LicAuth::Jwt.decode!(env[ENV_JWT])

        @app.call(env)
      rescue JSON::JWT::InvalidFormat
        invalid_format
      rescue JSON::JWS::VerificationFailed
        verification_failed
      end

      protected

      def authorisation_required?(env)
        env[ENV_REQUEST_METHOD] != METHOD_OPTIONS
      end

      def not_present
        [401, {}, [MultiJson.dump(error: URN_NOT_PRESENT)]]
      end

      def invalid_format
        [400, {}, [MultiJson.dump(error: URN_INVALID_FORMAT)]]
      end

      def verification_failed
        [401, {}, [MultiJson.dump(error: URN_VERIFICATION_FAILED)]]
      end
    end
  end
end
