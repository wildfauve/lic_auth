# frozen_string_literal: true
module LicAuth
  class ClientCredentials
    ENDPOINT = "/identity/oauth/token".freeze

    def initialize(client_id:, client_secret:, api_host: ENV["FLICK_API_HOST"])
      @client_id = client_id
      @client_secret = client_secret
      @api_host = api_host
    end

    def jwt
      if cached_jwt && valid?(jwt: cached_jwt)
        cached_jwt
      else
        @cached_jwt = fetch_new_token
      end
    end

    def auth_header
      "Bearer #{jwt}"
    end

    private

    attr_reader :client_id, :client_secret, :api_host, :cached_jwt

    def valid?(jwt:)
      !!LicAuth::Jwt.decode(jwt)
    end

    def fetch_new_token
      response = LicAuth::Client.post(ENDPOINT,
                                        base_uri: api_host,
                                        body: request_hash(client_id, client_secret))
      response["id_token"]
    end

    def request_hash(client_id, client_secret)
      {
        client_id:     client_id,
        client_secret: client_secret,
        grant_type:    "client_credentials"
      }
    end
  end
end
