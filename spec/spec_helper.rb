require 'vcr'

module AgentsAccessTokenFilter
  private

  def serializable_body(*)
    body = super
    body['string'].gsub!(/"access_token":\s*"\w+"/, '"access_token": "<<AGENT_ACCESS_TOKEN>>"')
    body['string'].gsub!(/"ip_address":\s*"[\d\.]+"/, '"ip_address": "127.0.0.1"')
    body
  end
end

VCR::Response.include(AgentsAccessTokenFilter)
VCR.configure do |config|
  config.configure_rspec_metadata!
  config.cassette_library_dir = 'spec/cassettes/'
  config.hook_into :faraday
  config.filter_sensitive_data('<<ACCESS_TOKEN>>') do
    test_okta_token
  end

  # Forces binary to be readable and modifiable json
  config.before_record do |i|
    i.response.body.force_encoding('UTF-8')
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'oktakit'

module TestClient
  extend RSpec::SharedContext
  let(:client) do
    Oktakit::Client.new(token: test_okta_token,
                        organization: test_okta_organization,
                        api_endpoint: test_okta_api_endpoint)
  end
end

RSpec.configure do |config|
  config.include TestClient
end

def test_okta_token
  ENV.fetch('OKTA_TEST_TOKEN', 'x' * 40)
end

def test_okta_organization
  ENV.fetch('OKTA_TEST_ORGANIZATION', 'okta-test')
end

def test_okta_api_endpoint
  ENV['OKTA_TEST_API_ENDPOINT']
end
