# frozen_string_literal: true
require "spec_helper"
require "lic_auth"

describe LicAuth::Can do
  context "invalid activity" do
    let(:invalid_no_action) { LicAuth::Can::Policy.new("lic:app_sales_product:resource:product:") }
    let(:invalid_resource_type) { LicAuth::Can::Policy.new("lic:app_sales_product:invalid:product:list") }
    let(:invalid_no_resouce) { LicAuth::Can::Policy.new("lic:app_sales_product:invalid::list") }

    it "should have errors" do
      expect(invalid_no_action.valid?).to be_falsy
      expect(invalid_resource_type.valid?).to be_falsy
      expect(invalid_no_resouce.valid?).to be_falsy
    end

    it "should have a error message" do
      expect(invalid_no_action.valid?).to be_falsy
      expect(invalid_no_action.errors).to eq ["action is blank or missing"]
    end
  end

  describe "valid activities" do
    let(:product_list)        { LicAuth::Can::Policy.new("lic:app_sales_product:resource:product:list") }
    let(:product_show)        { LicAuth::Can::Policy.new("lic:app_sales_product:resource:product:show") }
    let(:product_all)         { LicAuth::Can::Policy.new("lic:app_sales_product:resource:product:*") }
    let(:all_all)             { LicAuth::Can::Policy.new("lic:app_sales_product:resource:product:*") }

    context "errors" do
      it "should have no errors" do
        expect(product_list.valid?).to be_truthy
        expect(product_all.valid?).to be_truthy
        expect(all_all.valid?).to be_truthy
      end
    end

    describe "can?" do
      context "with no activities" do
        subject { LicAuth::Can::Can.new([]) }

        it "should deny access" do
          expect(subject.can?(app_name: "app_name", resource: "resouce", action: "action")).to be_falsy
        end
      end

      context "with activities" do
        subject { LicAuth::Can::Can.new([product_show, product_list]) }

        it "should allow access with matching activities" do
          expect(subject.can?(app_name: "app_sales_product", resource: "product", action: "list")).to be_truthy
          expect(subject.can?(app_name: "app_sales_product", resource: "product", action: "show")).to be_truthy
        end

        it "should deny with differnt action" do
          expect(subject.can?(app_name: "app_sales_product", resource: "product", action: "different")).to be_falsy
        end

        it "should deny with different resource" do
          expect(subject.can?(app_name: "app_sales_product", resource: "different", action: "list")).to be_falsy
        end

        it "should deny with different app_name" do
          expect(subject.can?(app_name: "different", resource: "different", action: "show")).to be_falsy
        end

        it "should allow access when action is missing" do
          expect(subject.can?(app_name: "app_sales_product", resource: "product")).to be_truthy
        end

        it "should allow access when resource and action are missing" do
          expect(subject.can?(app_name: "app_sales_product")).to be_truthy
        end
      end
    end

    describe "to_s" do
      it "should output the correct string representation of the object" do
        expect(product_list.to_s).to eq "lic:app_sales_product:resource:product:list"
      end
    end
  end
end
