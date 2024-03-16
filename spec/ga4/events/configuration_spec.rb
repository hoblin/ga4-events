# frozen_string_literal: true

RSpec.describe GA4::Events::Configuration do
  subject(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.measurement_id).to eq(ENV["GA4_MEASUREMENT_ID"])
      expect(config.api_secret).to eq(ENV["GA4_API_SECRET"])
      expect(config.logger).to be_a(Logger)
      expect(config.validation_mode).to be false
      expect(config.debug_mode).to be false
      expect(config.validate_events).to be true
      expect(config.max_retries).to eq(3)
      expect(config.retry_delay).to eq(1)
      expect(config.timeout).to eq(10)
      expect(config.fail_silently).to be true
    end
  end

  describe "#endpoint" do
    context "when validation_mode is false" do
      before do
        config.validation_mode = false
      end

      it "returns the production endpoint" do
        expect(config.endpoint).to eq(GA4::Events::Configuration::GA4_ENDPOINT)
      end
    end

    context "when validation_mode is true" do
      before do
        config.validation_mode = true
      end

      it "returns the validation endpoint" do
        expect(config.endpoint).to eq(GA4::Events::Configuration::GA4_VALIDATION_ENDPOINT)
      end
    end
  end

  describe "#valid?" do
    context "when measurement_id and api_secret are set" do
      before do
        config.measurement_id = "G-TEST123"
        config.api_secret = "secret"
      end

      it "returns true" do
        expect(config.valid?).to be true
      end
    end

    context "when measurement_id is missing" do
      before do
        config.measurement_id = nil
        config.api_secret = "secret"
      end

      it "returns false" do
        expect(config.valid?).to be false
      end
    end

    context "when api_secret is missing" do
      before do
        config.measurement_id = "G-TEST123"
        config.api_secret = nil
      end

      it "returns false" do
        expect(config.valid?).to be false
      end
    end

    context "when both are empty strings" do
      before do
        config.measurement_id = ""
        config.api_secret = ""
      end

      it "returns false" do
        expect(config.valid?).to be false
      end
    end
  end

  describe "#validate!" do
    context "when configuration is valid" do
      before do
        config.measurement_id = "G-TEST123"
        config.api_secret = "secret"
      end

      it "does not raise an error" do
        expect { config.validate! }.not_to raise_error
      end
    end

    context "when configuration is invalid" do
      before do
        config.measurement_id = nil
        config.api_secret = nil
      end

      it "raises a ConfigurationError" do
        expect { config.validate! }.to raise_error(GA4::Events::ConfigurationError)
      end
    end
  end
end
