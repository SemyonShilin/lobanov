require 'aruba/cucumber'

example_path = File.expand_path('../../../test_apps/rails_61', __FILE__)

require "#{example_path}/config/environment"

Aruba.configure do |config|
end
