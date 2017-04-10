# frozen_string_literal: true
require "spec_helper"
require "lic_auth/client"

# describe LicAuth::ClientCredentials do
#   context "retrieving activities for a token" do
#     let(:activities_hash) { [{ "policy" => "lic:customer_app:resource:dashboard:show" }] }
#
#     it "retrieves activities for a valid JWT" do
#       allow(LicAuth::Client).to receive(:get).with("/activities", base_uri: nil, query: { id_token: "valid_token" }).and_return(double(body: activities_hash.to_json))
#
#       expect(LicAuth::Activities.for_token("valid_token")).to eq(activities_hash)
#     end
#
#     it "returns an empty list for an invalid JWT" do
#       auth_error = LicAuth::Unauthorized.new("args", "response")
#       allow(LicAuth::Client).to receive(:get).with("/activities", base_uri: nil, query: { id_token: "invalid_token" }).and_raise(auth_error)
#
#       expect(LicAuth::Activities.for_token("invalid_token")).to eq([])
#     end
#   end
# end
