# frozen_string_literal: true

class GA4::Events::Configuration
  attr_accessor :measurement_id, :api_secret, :logger, :validation_mode, :debug_mode,
                :validate_events, :max_retries, :retry_delay, :timeout,
                :fail_silently

  # GA4 API endpoint
  # https://developers.google.com/analytics/devguides/collection/protocol/ga4/validating-events?client_type=firebase#send_events_for_validation
  GA4_ENDPOINT = "https://www.google-analytics.com/mp/collect"
  GA4_VALIDATION_ENDPOINT = "https://www.google-analytics.com/debug/mp/collect"

  def initialize
    @measurement_id = ENV["GA4_MEASUREMENT_ID"]
    @api_secret = ENV["GA4_API_SECRET"]
    @logger = Logger.new($stdout)
    @logger.level = Logger::WARN
    @validation_mode = false # Send to validation endpoint for server-side validation
    @debug_mode = false # Inject debug_mode param to show events in DebugView
    @validate_events = true
    @max_retries = 3
    @retry_delay = 1 # seconds
    @timeout = 10 # seconds
    @fail_silently = true
  end

  def endpoint
    validation_mode ? GA4_VALIDATION_ENDPOINT : GA4_ENDPOINT
  end

  def valid?
    !measurement_id.nil? && !measurement_id.empty? &&
      !api_secret.nil? && !api_secret.empty?
  end

  def validate!
    unless valid?
      raise GA4::Events::ConfigurationError, "measurement_id and api_secret must be configured"
    end
  end
end
