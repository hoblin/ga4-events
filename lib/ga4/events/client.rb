# frozen_string_literal: true

class GA4::Events::Client
  attr_reader :config

  def initialize(config = nil)
    @config = config || GA4::Events.configuration
  end

  # Send a single event
  def send_event(name, params = {}, client_id: nil, user_id: nil)
    event = GA4::Events::Event.new(name, params)

    send_batch([event], client_id: client_id, user_id: user_id)
  end

  # Send multiple events in a batch
  def send_batch(events, client_id: nil, user_id: nil)
    config.validate!

    # Convert events to Event objects if needed
    event_objects = events.map do |event|
      event.is_a?(GA4::Events::Event) ? event : GA4::Events::Event.new(event[:name], event[:params] || {})
    end

    # Validate events if enabled
    if config.validate_events
      invalid_events = event_objects.reject(&:valid?)

      unless invalid_events.empty?
        error_messages = invalid_events.flat_map(&:errors)

        handle_error("Event validation failed: #{error_messages.join(', ')}")

        return GA4::Events::Response.new(400, {}, error_messages)
      end
    end

    client_id ||= generate_client_id
    payload = build_payload(event_objects, client_id, user_id)

    # Send with retry logic
    send_with_retry(payload)
  end

  private

  def build_payload(events, client_id, user_id)
    payload = {
      client_id: client_id,
      events: events.map { |event| event.to_h(debug_mode: config.debug_mode) }
    }

    payload[:user_id] = user_id if user_id

    payload
  end

  def send_with_retry(payload)
    attempts = 0
    last_error = nil

    loop do
      attempts += 1

      begin
        response = perform_request(payload)

        log_response(response, payload)

        return response
      rescue StandardError => e
        last_error = e

        log_error("Attempt #{attempts} failed: #{e.message}")

        if attempts >= config.max_retries
          handle_error("Max retries (#{config.max_retries}) exceeded: #{e.message}")

          return GA4::Events::Response.new(0, {}, [e.message])
        end

        sleep(config.retry_delay)
      end
    end
  end

  def perform_request(payload)
    uri = build_uri
    http = create_http_client(uri)
    request = create_request(uri, payload)

    http_response = http.request(request)

    body = parse_response_body(http_response.body)
    errors = http_response.code.to_i >= 400 ? [http_response.message] : []

    GA4::Events::Response.new(http_response.code.to_i, body, errors)
  rescue StandardError => e
    raise e unless config.fail_silently

    GA4::Events::Response.new(0, {}, [e.message])
  end

  def build_uri
    uri = URI.parse(config.endpoint)
    uri.query = URI.encode_www_form(
      measurement_id: config.measurement_id,
      api_secret: config.api_secret
    )

    uri
  end

  def create_http_client(uri)
    Net::HTTP.new(uri.host, uri.port).tap do |http|
      http.use_ssl = true
      http.read_timeout = config.timeout
      http.open_timeout = config.timeout
    end
  end

  def create_request(uri, payload)
    Net::HTTP::Post.new(uri.request_uri).tap do |request|
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)
    end
  end

  def parse_response_body(body)
    return {} if body.nil? || body.empty?

    JSON.parse(body)
  rescue JSON::ParserError
    { raw: body }
  end

  def generate_client_id
    # ? might be the DebugView doesn't like when client_id is something like UUID, but with string like "debug" it's working
    if config.debug_mode
      "debug"
    else
      SecureRandom.uuid
    end
  end

  def log_response(response, payload)
    return unless config.logger

    if response.success?
      config.logger.info("GA4 Event sent successfully")

      if config.validation_mode || config.debug_mode
        config.logger.debug("Payload: #{payload}")
        config.logger.debug("Response: #{response.to_h}")
      end
    else
      config.logger.warn("GA4 Event failed: #{response}")
    end
  end

  def log_error(message)
    config.logger&.error(message)
  end

  def handle_error(message)
    log_error(message)

    raise GA4::Events::Error, message unless config.fail_silently
  end
end
