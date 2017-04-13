# frozen_string_literal: true
require "lic_auth/client/exceptions"
require "httparty"

module LicAuth
  class Client
    def self.get(*args)
      response = retry_request_wrapper(*args) do
        ClientHttp.get(*args)
      end
      response
    end

    def self.post(*args)
      response = retry_request_wrapper(*args) do
        ClientHttp.post(*args)
      end
      response
    end

    def self.put(*args)
      response = retry_request_wrapper(*args) do
        ClientHttp.put(*args)
      end
      response
    end

    def self.patch(*args)
      response = retry_request_wrapper(*args) do
        ClientHttp.patch(*args)
      end
      response
    end

    private

    RETRY_COUNT = 3
    def self.retry_request_wrapper(*args)
      args[1] ||= {}
      args[1][:headers] ||= {}
      headers = args[1][:headers]
      options = (args.last.is_a?(Hash) && args.last) || {}
      retries = RETRY_COUNT
      begin
        response = yield
        case response.code
        when 200..207
          response
        else
          path = args.try(:first)
          base_uri = options[:base_uri]
          raise (LicAuth::Exceptions::EXCEPTIONS_MAP[response.code] || LicAuth::UnknownException).new("#{base_uri}#{path}", response)
        end
      rescue => e
        retries -= 1
        retry unless options[:retry] == false || retries.zero? || ENV["RAILS_ENV"] == "development"
        raise e
      end
    end

    # This internal class does not raise exceptions, please use the Client class and handle or let exceptions bubble up
    class ClientHttp
      include ::HTTParty
      base_uri ENV["LIC_IDENTITY_HOST"]
      format :json
      read_timeout 10
    end
  end
end
