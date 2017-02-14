# frozen_string_literal: true
require "spec_helper"
require "lic_auth/client"

describe LicAuth::ClientCredentials do
  let(:client_credentials) { LicAuth::ClientCredentials.new(client_id: "mock_client_id", client_secret: "mock_client_secret") }
  let(:token_json) { { "sub" => "i123", "iat" => Time.now.to_i, "jti" => rand(2 << 64).to_s, "exp": (Time.now + 1.hour).to_i } }
  let(:encoded_token) { LicAuth::Jwt.encode(token_json) }
  let(:token_response) { { "id_token" => encoded_token } }

  before do
    allow(LicAuth::Client).to receive(:post).and_return(token_response)
  end

  context "making a client credentials call" do
    it "generates the correct parameters" do
      expected_body = {
        client_id:     "mock_client_id",
        client_secret: "mock_client_secret",
        grant_type:    "client_credentials"
      }
      expect(LicAuth::Client).to receive(:post).with("/oauth/token", base_uri: nil, body: expected_body).and_return(token_response)

      client_credentials.jwt
    end
  end

  context "after a successful client credentials call" do
    describe "jwt" do
      it "returns the jwt" do
        expect(client_credentials.jwt).to eq encoded_token
      end
    end

    describe "auth_header" do
      it "generates a valid auth header" do
        expect(client_credentials.auth_header).to eq "Bearer #{encoded_token}"
      end
    end
  end

  context "making multiple requests" do
    it "should store the jwt and re-use for subsequent requests" do
      expect(LicAuth::Client).to receive(:post).exactly(:once)

      client_credentials.auth_header
      client_credentials.auth_header
    end

    context "when the jwt has expired" do
      before do
        allow(LicAuth::Jwt).to receive(:decode).and_return(false)
      end

      it "should request a new jwt" do
        expect(LicAuth::Client).to receive(:post).exactly(:twice)

        client_credentials.auth_header
        client_credentials.auth_header
      end
    end
  end
end
