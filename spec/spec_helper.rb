# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "lic_auth"
require "byebug"
require "rack/test"
require "pry"

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each do |file|
  require file
end

LicAuth::PKI.dump_key_pair
