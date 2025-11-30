# frozen_string_literal: true

RSpec.describe GA4::Events::Event do
  describe "#initialize" do
    context "with string name and hash params" do
      subject(:event) { described_class.new("test_event", { key: "value" }) }

      it "creates an event with correct name and params" do
        expect(event.name).to eq("test_event")
        expect(event.params).to eq({ key: "value" })
      end
    end

    context "with symbol name" do
      subject(:event) { described_class.new(:test_event, {}) }

      it "converts symbol name to string" do
        expect(event.name).to eq("test_event")
      end
    end

    context "with nil params" do
      subject(:event) { described_class.new("test_event", nil) }

      it "accepts nil params" do
        expect(event.params).to be_nil
      end
    end
  end

  describe "#valid?" do
    subject(:event) { described_class.new(event_name, event_params) }

    context "with valid event" do
      let(:event_name) { "test_event" }
      let(:event_params) { { key: "value" } }

      it "returns true" do
        expect(event).to be_valid
      end
    end

    context "with empty event name" do
      let(:event_name) { "" }
      let(:event_params) { {} }

      it "returns false" do
        expect(event).not_to be_valid
      end
    end

    context "with event name too long" do
      let(:event_name) { "a" * 41 }
      let(:event_params) { {} }

      it "returns false" do
        expect(event).not_to be_valid
      end
    end

    context "with params not a hash" do
      let(:event_name) { "test_event" }
      let(:event_params) { "not a hash" }

      it "returns false" do
        expect(event).not_to be_valid
      end
    end

    context "with too many params" do
      let(:event_name) { "test_event" }
      let(:event_params) { (1..26).to_h { |i| ["param#{i}", "value"] } }

      it "returns false" do
        expect(event).not_to be_valid
      end
    end

    context "with param name too long" do
      let(:event_name) { "test_event" }
      let(:event_params) { { "a" * 41 => "value" } }

      it "returns false" do
        expect(event).not_to be_valid
      end
    end

    context "with string param value too long" do
      let(:event_name) { "test_event" }
      let(:event_params) { { key: "a" * 101 } }

      it "returns false" do
        expect(event).not_to be_valid
      end
    end

    context "with non-string values of any length" do
      let(:event_name) { "test_event" }
      let(:event_params) do
        {
          number: 12345678901234567890,
          array: [1, 2, 3, 4, 5]
        }
      end

      it "returns true" do
        expect(event).to be_valid
      end
    end
  end

  describe "#errors" do
    subject(:event) { described_class.new(event_name, event_params) }

    context "with valid event" do
      let(:event_name) { "test_event" }
      let(:event_params) { { key: "value" } }

      it "returns empty array" do
        expect(event.errors).to be_empty
      end
    end

    context "with empty event name" do
      let(:event_name) { "" }
      let(:event_params) { {} }

      it "returns error" do
        expect(event.errors).to include("Event name cannot be empty")
      end
    end

    context "with long event name" do
      let(:event_name) { "a" * 41 }
      let(:event_params) { {} }

      it "returns error" do
        expect(event.errors).to include("Event name cannot exceed 40 characters")
      end
    end

    context "with too many params" do
      let(:event_name) { "test_event" }
      let(:event_params) { (1..26).to_h { |i| ["param#{i}", "value"] } }

      it "returns error" do
        expect(event.errors).to include("Event cannot have more than 25 parameters")
      end
    end

    context "with long param name" do
      let(:event_name) { "test_event" }
      let(:event_params) { { "a" * 41 => "value" } }

      it "returns error" do
        expect(event.errors.first).to match(/Parameter name .* exceeds 40 characters/)
      end
    end

    context "with long param value" do
      let(:event_name) { "test_event" }
      let(:event_params) { { key: "a" * 101 } }

      it "returns error" do
        expect(event.errors.first).to match(/Parameter 'key' value exceeds 100 characters/)
      end
    end

    context "with non-hash params" do
      let(:event_name) { "test_event" }
      let(:event_params) { "not a hash" }

      it "returns error" do
        expect(event.errors).to include("Event params must be a Hash")
      end
    end

    context "with multiple validation errors" do
      let(:event_name) { "" }
      let(:event_params) { { "a" * 41 => "value" } }

      it "returns all errors" do
        expect(event.errors.length).to eq(2)
      end
    end
  end

  describe "#to_h" do
    subject(:event) { described_class.new("test_event", event_params) }

    let(:event_params) { { key: "value" } }

    context "without debug_mode" do
      it "returns a hash representation" do
        expect(event.to_h).to eq({
          name: "test_event",
          params: { key: "value" }
        })
      end
    end

    context "with debug_mode: false" do
      let(:result) { event.to_h(debug_mode: false) }

      it "does not inject debug_mode param" do
        expect(result[:params]["debug_mode"]).to be_nil
      end
    end

    context "with debug_mode: true" do
      let(:result) { event.to_h(debug_mode: true) }
      let(:original_params) { { key: "value" } }
      let(:event) { described_class.new("test_event", original_params) }

      it "injects debug_mode param" do
        expect(result[:params]["debug_mode"]).to eq("1")
        expect(result[:params][:key]).to eq("value")
      end

      context "when params are nil" do
        let(:event_params) { nil }

        it "handles nil params" do
          expect(result[:params]["debug_mode"]).to eq("1")
        end
      end

      it "does not modify original params" do
        event.to_h(debug_mode: true)

        expect(original_params["debug_mode"]).to be_nil
      end
    end
  end
end
