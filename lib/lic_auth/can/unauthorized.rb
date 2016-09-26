# frozen_string_literal: true
module LicAuth::Can
  class Unauthorized < RuntimeError
    def initialize(*args)
      super(args)
    end
  end
end
