def mock_authorized_for(policy, token = nil)
  mock_auth_header(token)
  allow(LicAuth::Activities).to receive(:for_token).and_return(generate_activities(policy))
end

def mock_unauthorized(token = nil)
  mock_auth_header(token)
  allow(LicAuth::Activities).to receive(:for_token).and_return([])
end

def mock_auth_header(token = nil)
  token ||= { sub: SecureRandom.uuid }
  header "Authorization", "Bearer #{LicAuth::Jwt.encode(token)}"
end

def generate_activities(policy)
  [
    { "policy" => policy }
  ]
end
