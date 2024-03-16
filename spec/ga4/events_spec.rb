# frozen_string_literal: true

RSpec.describe GA4::Events do
  let(:measurement_id) { "G-TEST123" }
  let(:api_secret) { "test_secret" }

  before do
    GA4::Events.configure do |config|
      config.measurement_id = measurement_id
      config.api_secret = api_secret
      config.logger = Logger.new(IO::NULL) # Suppress logs in tests
    end
  end

  after do
    GA4::Events.reset_configuration!
  end

  it "has a version number" do
    expect(GA4::Events::VERSION).not_to be_nil
  end

  describe ".configuration" do
    it "returns a Configuration object" do
      expect(GA4::Events.configuration).to be_a(GA4::Events::Configuration)
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      expect { |b| GA4::Events.configure(&b) }.to yield_with_args(GA4::Events.configuration)
    end

    context "when custom configuration values are provided" do
      before do
        GA4::Events.configure do |config|
          config.debug_mode = true
          config.max_retries = 5
        end
      end

      it "sets configuration values" do
        expect(GA4::Events.configuration.debug_mode).to be true
        expect(GA4::Events.configuration.max_retries).to eq(5)
      end
    end
  end

  describe ".track" do
    let(:client) { instance_double(GA4::Events::Client) }

    before do
      allow(GA4::Events::Client).to receive(:new).and_return(client)
    end

    it "creates a client and sends the event" do
      expect(client).to receive(:send_event).with("test_event", { key: "value" }, client_id: "client123", user_id: nil)

      GA4::Events.track("test_event", { key: "value" }, client_id: "client123")
    end
  end

  describe ".track_batch" do
    let(:client) { instance_double(GA4::Events::Client) }
    let(:events) { [{ name: "event1", params: {} }, { name: "event2", params: {} }] }

    before do
      allow(GA4::Events::Client).to receive(:new).and_return(client)
    end

    it "creates a client and sends batch events" do
      expect(client).to receive(:send_batch).with(events, client_id: "client123", user_id: nil)

      GA4::Events.track_batch(events, client_id: "client123")
    end
  end
end
