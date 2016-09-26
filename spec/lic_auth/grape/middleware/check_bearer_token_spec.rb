# frozen_string_literal: true
require "spec_helper"
require "grape"
require "lic_auth/grape/middleware/check_bearer_token"

describe "with_mock_keys" do
  class BearerTokenAuthApi < Grape::API
    include LicAuth::Middleware::CheckBearerToken
    resource :auth do
      desc "auth"
      get("/endpoint") do
      end
    end
  end

  class BearerTokenErrorApi < Grape::API
    include LicAuth::Middleware::CheckBearerToken
    resource :errors do
      get("/jwt_invalid_format") do
        raise JSON::JWT::InvalidFormat
      end

      get("/jwt_verification_failed") do
        raise JSON::JWS::VerificationFailed
      end
    end
  end

  describe "auth" do
    include Rack::Test::Methods
    let(:app) { BearerTokenAuthApi }
    let(:action) { get "/auth/endpoint" }

    before { action }

    context "no token" do
      it "responds with status 400" do
        expect(last_response.status).to eql(400)
      end
    end

    context "with token" do
      let(:action) do
        header "Authorization", "Bearer #{id_token}"
        get "/auth/endpoint"
      end

      let(:id_token) { LicAuth::Jwt.encode(token_json) }
      context "valid token" do
        let(:token_json) { { "sub" => "i123", "iat" => Time.now.to_i, "jti" => rand(2 << 64).to_s, "exp": (Time.now + 1.hour).to_i } }
        it "responds with status 200" do
          expect(last_response.status).to eql(200)
        end
      end

      context "expired token" do
        let(:token_json) { { "sub" => "i123", "iat" => Time.now.to_i, "jti" => rand(2 << 64).to_s, "exp": (Time.now - 2.second).to_i } }
        it "responds with status 401" do
          expect(last_response.status).to eql(401)
        end
      end
    end
  end
end

describe "Grape Defaults Api Error Handling" do
  include Rack::Test::Methods
  let(:app) { BearerTokenErrorApi }

  before { action }
  subject { last_response }

  describe "handling of JSON::JWS::VerificationFailed" do
    let(:token_json) { { "sub" => "i123", "iat" => Time.now.to_i, "jti" => rand(2 << 64).to_s, "exp": (Time.now - 2.second).to_i } }

    let(:id_token) { LicAuth::Jwt.encode(token_json) }

    let(:action) do
      header "Authorization", "Bearer #{id_token}"
      get "/errors/jwt_verification_failed.json"
    end

    it "responds with status 401" do
      expect(last_response.status).to eql(401)
    end

    it "responds with the correct error in the json body" do
      expect(last_json_response["error"]).to eql("urn:lic:authentication:error:jwt_expired")
    end
  end

  describe "handling of JSON::JWT::InvalidFormat" do
    let(:action) { get "/errors/jwt_invalid_format.json" }

    it "responds with status 400" do
      expect(last_response.status).to eql(400)
    end

    it "responds with the correct error in the json body" do
      expect(last_json_response["error"]).to eql("urn:lic:authentication:error:jwt_invalid_format")
    end
  end
end
