# frozen_string_literal: true
require "json/jwt"
require "openssl"

module LicAuth
  class PKI
    # Signing parameters:
    # "{\"typ\":\"JWT\",\"alg\":\"HS256\"}"
    #
    KEY_LENGTH = 2048
    JWT_PRIVATE_KEY = "IDENTITY_JWT_PRIVATE_KEY".freeze
    JWT_PUBLIC_KEY = "IDENTITY_JWT_PUBLIC_KEY".freeze

    def self.private_key
      @@private_key ||= ENV[JWT_PRIVATE_KEY] && OpenSSL::PKey::RSA.new(ENV[JWT_PRIVATE_KEY]) || raise(raise_message(JWT_PRIVATE_KEY))
    end

    def self.public_key
      @@public_key ||= ENV[JWT_PUBLIC_KEY] && OpenSSL::PKey::RSA.new(ENV[JWT_PUBLIC_KEY]) || raise(raise_message(JWT_PUBLIC_KEY))
    end

    def self.generate_key_pair
      key_pair = OpenSSL::PKey::RSA.new KEY_LENGTH
      [key_pair.to_pem, key_pair.public_key.to_pem]
    end

    def self.dump_key_pair
      key, pub_key = generate_key_pair
      ENV[JWT_PRIVATE_KEY] = key
      ENV[JWT_PUBLIC_KEY] = pub_key
      [key, pub_key]
    end

    def self.raise_message(missing_var)
      "No #{missing_var} ENV var. Run LicAuth::PKI.dump_key_pair to set environment variables"
    end
  end

  class Jwt
    JWT_SYMMETRIC_SECRET = "JWT_SYMETRIC_SECRET".freeze

    def self.decode!(jwt)
      raise JSON::JWT::InvalidFormat unless jwt
      id_token = LicAuth::Jwt.decode(jwt)
      raise JSON::JWS::VerificationFailed unless id_token
      id_token
    end

    def self.decode(id_token)
      return nil if id_token.nil?
      decoded_jwt = JSON::JWT.decode(id_token, PKI.public_key)
      jwt_expired?(decoded_jwt) ? nil : decoded_jwt
    end

    def self.encode(json)
      JSON::JWT.new(json).sign(PKI.private_key, :RS512).to_s
    end

    # Returns the plain claims for a given (hmac) signed jwt
    #
    # When given a jwt wit a hmac signature, it
    #
    # 1. the jwt is UrlSafeBase64 decoded and splitted into
    #    header, claims, given_signature
    #
    # 2. for header + claims a HAMC is calculated with the
    #    given secret.
    #
    # 3. the calculated signature is compared to the given_signature
    #
    # 4.1. In case of a mach, the claims are returned.
    # 4.2. In case of a mismatch, errors are raised. See:
    #      https://github.com/nov/json-jwt/blob/master/lib/json/jws.rb
    def self.decode_symmetric(jot)
      return nil if jot.nil?
      JSON::JWT.decode(jot, symmetric_key)
    end

    # Returns jwt with a HMAC signature for given claims
    #
    # The base message that is signed consists of "."-separated
    # strings:
    #
    # - The jwt header
    #   e.g. {"typ":"JWT","alg":"HS256"}
    #
    # - the json content
    #   e.g. {"sub": "asdasd"}
    #
    # Attached to this message is the HMAC that can be reproduced as:
    #
    #   OpenSSL::HMAC.digest(
    #     OpenSSL::Digest::Digest.new("sha256"),
    #     "secret",
    #     "message")
    #
    # #.to_s returns the elements UrlSafeBase64 decoded
    def self.encode_symmetric(json)
      JSON::JWT.new(json).sign(symmetric_key).to_s
    end

    private

    def self.symmetric_key
      ENV[JWT_SYMMETRIC_SECRET] || "7195a5c92aafb7eaa2015941a103a8bae6acdb58d0c3e2fb"
    end

    def self.jwt_expired?(decoded_jwt)
      decoded_jwt["exp"] ? decoded_jwt["exp"].to_i < Time.now.to_i : false
    end
  end
end
