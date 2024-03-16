VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [:method, :uri, :body]
  }
  # Filter sensitive data
  config.filter_sensitive_data('<MEASUREMENT_ID>') { ENV['GA4_MEASUREMENT_ID'] }
  config.filter_sensitive_data('<API_SECRET>') { ENV['GA4_API_SECRET'] }
end
