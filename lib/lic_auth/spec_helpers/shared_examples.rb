RSpec.shared_examples_for "a JWT endpoint" do
  require "rack/test"

  include Rack::Test::Methods

  let(:valid_but_unverified_jwt) { "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzUxMiJ9.eyJzdWIiOiIyMGJhMmZhZi1jYTQ3LTQ0OGQtOTQ4Mi04ZjQ0YzlmMjRmZjEifQ.yMA_hRKA1TzypZdeDp6f1VHPb83VuuJS_-t4eSaclQIDwiNqXwzguUDGSjDSdoiZVaeHgHTzR9EUrk6iwPXAignKsA8hindLjoA_Z9QgYdTNl0g_c2eG_5odHpsFV8yvI_Qc140ObgB0M3iJ-ahOhrXIOVQ_DzXI5klzCRQWEeTBjUuw0LWXIdUxrb-FjEPiVtgJ8ibpobrXDdSUDBjvWLiVmb-8qVaGAKys4d0RDaoZUJHXJFGB46z_JstiqR0sQf20G89IpWXh174B8oDQoXgY2jR_vZvAvAl3Wjhs9t7EzT-e0XVi8G0_1E3qtuySKODWalMExnRkWd7ozc1OW" }

  def app
    subject
  end

  def last_json
    MultiJson.load(last_response.body)
  end

  before do
    @endpoint_method ||= "get"
  end

  context "authentication" do
    it "should allow OPTIONS requests" do
      header "Origin", "http://example.com"
      header "Access-Control-Request-Method", @endpoint_method

      options @endpoint_path
      expect(last_response).to be_successful
    end

    it "should require a bearer token" do
      send @endpoint_method, @endpoint_path

      expect(last_response.status).to eq(401)

      expect(last_json).to eq("error" => "urn:lic:authentication:error:token_not_present")
    end

    it "should require a syntactically valid JWT" do
      header "Authorization", "Bearer pickle"

      send @endpoint_method, @endpoint_path

      expect(last_response.status).to eq(400)

      expect(last_json).to eq("error" => "urn:lic:authentication:error:token_invalid_format")
    end

    it "should require a correctly signed JWT" do
      header "Authorization", "Bearer #{valid_but_unverified_jwt}"

      send @endpoint_method, @endpoint_path

      expect(last_response.status).to eq(401)

      expect(last_json).to eq("error" => "urn:lic:authentication:error:token_verification_failed")
    end

    it "should support broken Android authentication without Bearer prefix" do
      header "Authorization", valid_but_unverified_jwt

      send @endpoint_method, @endpoint_path

      expect(last_response.status).to eq(401)

      expect(last_json).to eq("error" => "urn:lic:authentication:error:token_verification_failed")
    end
  end
end
