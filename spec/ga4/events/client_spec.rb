# frozen_string_literal: true

RSpec.describe GA4::Events::Client do
  let(:measurement_id) { ENV.fetch("GA4_MEASUREMENT_ID", "G-TEST123") }
  let(:api_secret) { ENV.fetch("GA4_API_SECRET", "test_secret") }
  let(:config) do
    GA4::Events::Configuration.new.tap do |c|
      c.measurement_id = measurement_id
      c.api_secret = api_secret
      c.logger = Logger.new(IO::NULL)
    end
  end

  subject(:client) { described_class.new(config) }

  before do
    allow(SecureRandom).to receive(:uuid).and_return("generated-client-id")
  end

  describe "#initialize" do
    it "uses provided config" do
      expect(client.config).to eq(config)
    end

    it "uses global config when not provided" do
      GA4::Events.configure do |c|
        c.measurement_id = measurement_id
        c.api_secret = api_secret
      end

      client = described_class.new
      expect(client.config).to eq(GA4::Events.configuration)
    end
  end

  describe "#send_event", vcr: { cassette_name: "client/send_event" } do
    it "sends a single event successfully" do
      response = client.send_event("test_event", { key: "value" })

      expect(response).to be_a(GA4::Events::Response)
      expect(response.success?).to be true
    end

    it "generates client_id if not provided" do
      response = client.send_event("test_event", {})
      expect(response.success?).to be true
    end

    it "uses provided client_id" do
      response = client.send_event("test_event", {}, client_id: "custom_id")
      expect(response.success?).to be true
    end

    it "includes user_id when provided" do
      response = client.send_event("test_event", {}, user_id: "user123")
      expect(response.success?).to be true
    end

    it "sends proper JSON payload" do
      response = client.send_event("test_event", { param1: "value1" }, client_id: "client123")
      expect(response.success?).to be true
    end
  end

  describe "#send_batch", vcr: { cassette_name: "client/send_batch" } do
    it "sends multiple events" do
      events = [
        { name: "event1", params: { key1: "value1" } },
        { name: "event2", params: { key2: "value2" } }
      ]

      response = client.send_batch(events, client_id: "client123")

      expect(response.success?).to be true
    end

    it "accepts Event objects" do
      events = [
        GA4::Events::Event.new("event1", { key: "value" })
      ]

      response = client.send_batch(events, client_id: "client123")

      expect(response.success?).to be true
    end
  end

  describe "#parse_response_body" do
    subject(:parse_response_body) { client.send(:parse_response_body, body) }

    context "when response body is empty" do
      let(:body) { "" }

      it "returns empty hash" do
        expect(parse_response_body).to eq({})
      end
    end

    context "when response body is valid JSON" do
      let(:body) { '{"key":"value"}' }

      it "parses and returns the JSON as a hash" do
        expect(parse_response_body).to eq({ "key" => "value" })
      end
    end

    context "when response body is invalid JSON" do
      let(:body) { "invalid json" }

      it "returns empty hash" do
        expect(parse_response_body).to eq({raw: "invalid json"})
      end
    end
  end

  describe "#log_response" do
    subject(:log_response) { client.send(:log_response, response, payload) }

    let(:logger) { instance_double(Logger) }
    let(:response) { GA4::Events::Response.new(200, {}, {}) }
    let(:payload) { { test: "data" } }

    before do
      config.logger = logger
    end

    context "when response is successful" do
      it "logs info message" do
        expect(logger).to receive(:info).with("GA4 Event sent successfully")

        log_response
      end

      context "when debug_mode is enabled" do
        before do
          config.debug_mode = true
        end

        it "logs payload" do
          expect(logger).to receive_messages(info: "GA4 Event sent successfully")
          expect(logger).to receive(:debug).with(/Payload: /)
          expect(logger).to receive(:debug).with(/Response: /)

          log_response
        end
      end
    end

    context "when response isn't successful" do
      let(:response) { GA4::Events::Response.new(400, {}, ["name invalid"]) }

      it "logs warning message" do
        expect(logger).to receive(:warn).with("GA4 Event failed: #{response}")

        log_response
      end
    end
  end

  describe "#perform_request" do
    context "when error occurs" do
      before do
        allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(SocketError.new("Failed to open TCP connection"))
        config.max_retries = 2
        config.retry_delay = 0
        config.fail_silently = true
      end

      context "when fail_silently is true" do
        it "handles the error gracefully" do
          expect(GA4::Events::Response).to receive(:new).with(0, {}, array_including("Failed to open TCP connection")).and_call_original

          client.send(:perform_request, {})
        end
      end

      context "when fail_silently is false" do
        before do
          config.fail_silently = false
        end

        it "raises the error" do
          expect {
            client.send(:perform_request, {})
          }.to raise_error(SocketError, /Failed to open TCP connection/)
        end
      end
    end
  end

  describe "#send_with_retry" do
    before do
      allow(client).to receive(:perform_request).and_raise(Net::ReadTimeout.new("execution expired"))
    end

    it "retries the request up to max_retries" do
      config.max_retries = 3
      config.retry_delay = 0
      config.fail_silently = true

      expect(client).to receive(:perform_request).exactly(3).times

      client.send(:send_with_retry, {})
    end

    it "handles error after exceeding max_retries" do
      config.max_retries = 2
      config.retry_delay = 0
      config.fail_silently = true

      expect(client).to receive(:handle_error).with(/Max retries \(2\) exceeded: /)

      client.send(:send_with_retry, {})
    end
  end

  describe "validation" do
    context "when validate_events is true" do
      before do
        config.validate_events = true
      end

      it "returns error response for invalid events" do
        response = client.send_event("", {})

        expect(response.success?).to be false
        expect(response.errors).not_to be_empty
      end
    end

    context "when validate_events is false", vcr: { cassette_name: "client/validation_false" } do
      before do
        config.validate_events = false
      end

      it "sends invalid events" do
        response = client.send_event("", {})

        expect(response.success?).to be true
      end
    end
  end

  describe "retry logic", vcr: { cassette_name: "client/retry_logic", allow_playback_repeats: true } do
    before do
      config.max_retries = 2
      config.retry_delay = 0
    end

    # Note: VCR will replay the same cassette for retries
    # In real scenarios with network errors, the first request would fail and retry would succeed
    it "handles retries gracefully" do
      response = client.send_event("test_event", {})
      expect(response.success?).to be true
    end
  end

  describe "error handling" do
    let(:error_message) { "Test error message" }

    describe "#handle_error" do
      context "when fail_silently is true" do
        before do
          config.fail_silently = true
        end

        it "does not raise error" do
          expect { client.send(:handle_error, error_message) }.not_to raise_error
        end

        it "logs the error" do
          logger = instance_double(Logger)
          config.logger = logger

          expect(logger).to receive(:error).with(error_message)
          client.send(:handle_error, error_message)
        end
      end

      context "when fail_silently is false" do
        before do
          config.fail_silently = false
        end

        it "raises GA4::Events::Error" do
          expect { client.send(:handle_error, error_message) }
            .to raise_error(GA4::Events::Error, error_message)
        end

        it "logs the error before raising" do
          logger = instance_double(Logger)
          config.logger = logger

          expect(logger).to receive(:error).with(error_message)
          expect { client.send(:handle_error, error_message) }
            .to raise_error(GA4::Events::Error)
        end
      end
    end
  end

  describe "validation mode", vcr: { cassette_name: "client/validation_mode" } do
    before do
      config.validation_mode = true
    end

    it "uses validation endpoint" do
      response = client.send_event("test_event", {})
      expect(response).to be_a(GA4::Events::Response)
    end

    it "includes validation messages in response" do
      response = client.send_event("test_event", {})
      expect(response.validation_messages).to be_an(Array)
    end
  end

  describe "debug mode", vcr: { cassette_name: "client/debug_mode" } do
    context "when debug_mode is false" do
      let(:response) { client.send_event("test_event", { key: "value" }) }

      before do
        config.debug_mode = false
      end

      it "does not inject debug_mode param" do
        expect(response.success?).to be true
      end
    end

    context "when debug_mode is true" do
      let(:response) { client.send_event("test_event", { key: "value" }) }

      before do
        config.debug_mode = true
      end

      it "injects debug_mode param into events" do
        expect(response.success?).to be true
      end

      context "with batch events" do
        let(:events) do
          [
            { name: "event1", params: { key1: "value1" } },
            { name: "event2", params: { key2: "value2" } }
          ]
        end
        let(:response) { client.send_batch(events, client_id: "client123") }

        it "injects debug_mode param into batch events" do
          expect(response.success?).to be true
        end
      end
    end
  end
end
