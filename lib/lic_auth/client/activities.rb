# frozen_string_literal: true
module LicAuth
  class Activities
    def self.for_token(id_token, api_host: ENV["LIC_API_HOST"])
      response = LicAuth::Client.get("/activities",
                                       base_uri: api_host,
                                       query: { id_token: id_token })
      JSON.parse response.body
    rescue LicAuth::Unauthorized => e
      []
    end
  end
end
