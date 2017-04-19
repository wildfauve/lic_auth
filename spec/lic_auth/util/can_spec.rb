# frozen_string_literal: true
require "spec_helper"
require "lic_auth/util/can"

describe LicAuth::Util::Can do
  subject { LicAuth::Util::Can }

  describe "#can?" do
    let(:user) { double(:user) }
    let(:id_token) { LicAuth::Jwt.encode({ "sub" => "i123", "iat" => Time.now.to_i, "jti" => rand(2 << 64).to_s, "exp": (Time.now + 1.hour).to_i }) }

    before do
      allow(LicAuth::Userinfo).to receive(:for_token) { {"sub" => "i123", "allowed_activities" => ["lic:app_sales_product:resource:product:list"] } }
    end


    context "with user policies" do
      context "without activities" do
        let(:user) { double(:user, policies: []) }

        it "denies access" do
          expect(subject.can?(user: user, id_token: id_token, app_name: "app_sales_product", resource: "product", action: "list")).to be false
        end
      end

      context "with activities" do
        let(:user) { double(:user, policies: ["lic:app_sales_product:resource:product:list"]) }

        it "allows access" do
          expect(subject.can?(user: user, id_token: id_token, app_name: "app_sales_product", resource: "product", action: "list")).to be true
        end
      end
    end

    context "without a user" do
      it "fetches activities for the id_token" do
        expect(LicAuth::Userinfo).to receive(:for_token)
        subject.can?(user: nil, id_token: id_token, app_name: "app_sales_product", resource: "product", action: "list")
      end

      context "without activities" do
        it "denies access" do
          expect(subject.can?(user: nil, id_token: id_token, app_name: "app_sales_product", resource: "product", action: "no_access")).to be false
        end
      end

      context "with activities" do
        it "allows access" do
          expect(subject.can?(user: nil, id_token: id_token, app_name: "app_sales_product", resource: "product", action: "list")).to be true
        end
      end
    end
  end

  describe "#can!" do

    context "authorized" do
      it "allows access" do
        allow(subject).to receive(:can?) { true }

        expect(subject.can!(user: nil, id_token: "token", app_name: "app_sales_product", resource: "product", action: "list")).to be nil
      end
    end

    context "unauthorized" do
      it "raises LicAuth::Can::Unauthorized" do
        allow(subject).to receive(:can?) { false }

        expect{ subject.can!(user: nil, id_token: "token", app_name: "app_sales_product", resource: "product", action: "list") }.to raise_error(LicAuth::Can::Unauthorized)
      end
    end
  end

end
