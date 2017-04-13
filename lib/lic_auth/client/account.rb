module LicAuth
  class Account
    def self.all(api_token, api_host: ENV["LIC_IDENTITY_HOST"])
      response = LicAuth::Client.get("/api/client_accounts",
                                       base_uri: api_host,
                                       headers: {authorization: api_token })
      JSON.parse response.body
    rescue LicAuth::Unauthorized => e
      []
    end

  end
end
