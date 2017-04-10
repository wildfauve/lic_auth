# Lic Auth

LIC Auth is a Ruby library that performs some common functions with Identity and JWTs.  Its like a post modern Night Club bouncer, for no reason really.

## Getting Started

Add `gem lic_auth` to the GemFury block of your gemfile.

`bundle install`

## Playing with Tokens

Configure yourself a client that has access to the client credentials grant type.  Our internal systems will have this sort of permission.

Assuming you have Identity running locally, and you have the client_id secret for your highly trusted client, then do this...

```ruby
require "lic_auth/client"

authorisation = LicAuth::ClientCredentials.new(api_host: "http://localhost:5000", client_id: c, client_secret: s)
token = authorisation.jwt
```

If all works well, the token will be JWT that has been signed by Identity.

To decode the JWT, try this:

```ruby
LicAuth::Jwt.decode(token)
```

This should given you a decoded JWT, which might look a little like this:

```ruby
{
  "iss"=>"https://id.lic.co.nz",
  "sub"=>"c1df528e-1cba-480a-9f19-3704eea2c5ec",
  "aud"=>"53be0fe74d61748ee5020000",
  "exp"=>1483478858,
  "amr"=>[],
  "iat"=>1478208458,
  "azp"=>"332cfa87-f32f-4766-9314-38c96863f36f"
}
```

Then, you can get the system user's activities (the user is a system, in the Alice in Wonderland meaning of the sentence) by using the userinfo endpoint

```ruby
LicAuth::Userinfo.for_token(j, api_host: "http://localhost:5000")
```

Which will return activities like:

```ruby
{"sub"=>"b6cedb19-f868-4ad8-a028-49d25fa34b8e",
 "email_verified"=>true,
 "preferred_name"=>"Dinsdale de Llama",
 "preferred_username"=>"dinsdale@example.com",
 "updated_at"=>"2017-04-11T10:47:30+12:00",
 "allowed_activities"=>
  ["lic:identity:resource:termsconditions:update",
   "lic:identity:resource:termsconditions:show",
   "lic:identity:resource:termsconditions:create",
   "lic:surveil:resource:authz:list",
   "lic:identity:resource:account:create"]
```



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
