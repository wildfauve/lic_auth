# frozen_string_literal: true
require "spec_helper"

require "lic_auth"

require "dotenv"
Dotenv.load

describe LicAuth::Jwt do
  before :all do
    @key = ENV[LicAuth::PKI::JWT_PRIVATE_KEY]
    @pub_key = ENV[LicAuth::PKI::JWT_PUBLIC_KEY]
  end

  let(:valid_token) { { "hello" => "world", "iat" => Time.now.to_i, "jti" => rand(2 << 64).to_s, 'exp': (Time.now + 1.hour).to_i } }
  let(:expired_token) { { "hello" => "world", 'exp': Time.now - 1.hour } }

  context "JWT is valid" do
    let(:encoded) { LicAuth::Jwt.encode(valid_token) }

    it "should encode to a JOT" do
      expect(encoded).to be_a String
    end

    fit "should decode a JOT" do
      decoded = LicAuth::Jwt.decode(encoded)
      expect(decoded).to be_a Hash
      expect(decoded["hello"]).to eq "world"
    end
  end

  context "JWT is nil" do
    let(:encoded) { nil }

    it "should not decode a valid jwt" do
      decoded = LicAuth::Jwt.decode(encoded)
      expect(decoded).to be_nil
    end
  end

  context "JWT is expired" do
    let(:encoded) { LicAuth::Jwt.encode(expired_token) }

    it "should not decode a valid jwt" do
      decoded = LicAuth::Jwt.decode(encoded)
      expect(decoded).to be_nil
    end
  end

  context "#decode!" do
    subject { LicAuth::Jwt.decode!(jwt) }

    context "JWT is nil" do
      let(:jwt) { nil }

      it "should raise on nil" do
        expect { subject }.to raise_error(JSON::JWT::InvalidFormat)
      end
    end

    context "JWT is expired" do
      let(:jwt) { LicAuth::Jwt.encode(expired_token) }

      it "should raise on expired token" do
        expect { subject }.to raise_error(JSON::JWS::VerificationFailed)
      end
    end

    context "valid token" do
      let(:jwt) { LicAuth::Jwt.encode(valid_token) }

      it "should not raise" do
        expect { subject }.not_to raise_error
      end

      it "should be a hash" do
        expect(subject).to be_a Hash
      end
    end
  end

  context "symetric" do
    subject do
      { "hello" => "world" }
    end

    it "should decode a JOT" do
      encoded = LicAuth::Jwt.encode_symmetric(subject)

      expect(encoded).to be_a String

      decoded = LicAuth::Jwt.decode_symmetric(encoded)
      expect(decoded).to be_a Hash
      expect(decoded["hello"]).to eq "world"
    end
  end
end
