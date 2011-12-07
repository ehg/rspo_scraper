$LOAD_PATH.unshift File.dirname(__FILE__) + '/..'
 
require 'rubygems'
require 'rspec'
require 'vcr'
require 'webmock/rspec'
require 'bourne'
require 'time'
require 'scraperwiki'
require './scraperwiki-dev'

VCR.config do |c|
	c.cassette_library_dir = 'fixtures/vcr_cassettes'
	c.stub_with :webmock
end

RSpec.configure do |c|
  c.extend VCR::RSpec::Macros
	c.mock_framework = :mocha
end

