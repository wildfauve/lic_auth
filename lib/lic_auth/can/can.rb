# frozen_string_literal: true
module LicAuth::Can
  class Can
    def initialize(activities)
      @activities = (activities || []).collect do |act_in_string_or_object|
        act_in_string_or_object.is_a?(String) ? Policy.new(act_in_string_or_object) : act_in_string_or_object
      end
    end

    def can?(app_name:, resource: nil, action: nil)
      Policy.find(@activities, app_name: app_name, resource: resource.to_s, action: action.to_s)
    end
  end
end
