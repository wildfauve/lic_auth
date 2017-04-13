module LicAuth
  class Concepts
    def self.scopes(api_host: ENV["LIC_IDENTITY_HOST"])
      response = LicAuth::Client.get("/api/concepts/scopes",
                                       base_uri: api_host)
      JSON.parse response.body
    rescue LicAuth::Unauthorized => e
      []
    end

    def self.roles(api_host: ENV["LIC_IDENTITY_HOST"])
      response = LicAuth::Client.get("/api/concepts/roles",
                                       base_uri: api_host)
      JSON.parse response.body
    rescue LicAuth::Unauthorized => e
      []
    end

  end

end
