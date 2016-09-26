# Lic Auth

Some things to help you build and call Lic API's secured by [Identity Service](https://github.com/LicElectric/identity_service)

## Getting Started

Add `gem lic_auth` to the GemFury block of your gemfile.

`bundle install`

## Securing your API

Lic Auth provides Rack middleware to verify that the caller has provided an Authorization header that contains a valid JWT signed by the identity service:

```ruby
require "lic_auth/rack"

class MyApi < Grape::API
  use LicAuth::Rack::CheckBearerToken
end
```

Lic Auth also provides a Grape helper to verify that the JWT is authorised to perform a specific action. The `Can` helper also provides helper methods for accessing the `jwt` and the `id_token` (the decoded JWT):

```ruby
require "lic_auth/grape"

helpers LicAuth::Grape::Helpers::Can

# And then call it like this (the helper will send an error
# response back to the caller if they are not authorized):
before do
  can!(id_token: jwt, app_name: 'event_notifier', resource: 'notification_preferences', action: 'list')
end
```

_Note: There is also a Grape middleware to check the bearer token which is deprecated but still used by some services._

## Calling Identity Service APIs

To call Identity Service APIs you will need the following env vars:

```
FLICK_API_HOST=https://uat.lic.energy
```

Lic Auth contains a client for calling the Identity Service client credentials api:

**Client Credentials token grant:**

```ruby
require "lic_auth/client"
auth = LicAuth::ClientCredentials.new(
  client_id: ENV["IDENTITY_CLIENT_ID"],
  client_secret: ENV["IDENTITY_CLIENT_SECRET"]
)

auth.jwt         # JWT
auth.auth_header # "Bearer #{jwt}"
```

## Test Utilities

There are some other Lic Auth classes that you may wish to access directly in your services specs, to make these helpers available:

```ruby
require "lic_auth/spec_helper"
```

These helpers are designed to be used with `Rack::Test`:

```ruby
require 'rack/test'
include Rack::Test::Methods
```

To generate a key pair for encoding and decoding JWTs (this should happen once at the start of your spec run, so probably in `spec_helper.rb`):

```ruby
LicAuth::PKI.dump_key_pair
```

To attach a valid auth header to a request:

```ruby
mock_auth_header # Or if you already have a user, then: mock_auth_header(sub: your_users_sub)
post '/event_notifier/app_configurations'
```

Of if you already have a user and want to use an auth header for that user:

```ruby
mock_auth_header(sub: your_users_sub)
post '/event_notifier/app_configurations'
```

To generate an authorized header for your request:

```ruby
mock_authorized_for("lic:event_notifier:resource:app_configurations:create")
post '/event_notifier/app_configurations'
```

To generate an unauthorized header for your request:

```ruby
mock_unauthorized
post '/event_notifier/app_configurations'
```

You can also use the shared examples in Lic Auth to verify that your api is secure:

```ruby
require "lic_auth/spec_helper"

RSpec.describe API::Root, type: :request do
  it_behaves_like "a JWT endpoint" do
    before do
      @endpoint_path = "/event_notifier/app_configurations"
      @endpoint_method = :post
    end
  end
end
```



## Contributing
