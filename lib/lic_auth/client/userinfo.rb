# frozen_string_literal: true
module LicAuth
  class Userinfo
    def self.for_token(id_token, api_host: ENV["LIC_IDENTITY_HOST"])
      response = LicAuth::Client.get("/userinfo",
                                       base_uri: api_host,
                                       query: {id_token: id_token },
                                       headers: {"AUTHORIZATION" => id_token})

      JSON.parse response.body
    rescue LicAuth::Unauthorized => e
      []
    end
  end
end
