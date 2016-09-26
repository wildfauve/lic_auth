# frozen_string_literal: true
def last_json_response
  JSON.parse(last_response.body)
end
