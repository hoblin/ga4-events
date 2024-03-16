# frozen_string_literal: true

RSpec.describe GA4::Events::Response do
  describe "#initialize" do
    subject(:response) { described_class.new(200, { key: "value" }) }

    it "creates a response with status_code and body" do
      expect(response.status_code).to eq(200)
      expect(response.body).to eq({ key: "value" })
      expect(response.errors).to be_empty
    end

    context "with errors" do
      subject(:response) { described_class.new(400, {}, ["Error message"]) }

      it "creates a response with errors" do
        expect(response.errors).to eq(["Error message"])
      end
    end
  end

  describe "#success?" do
    context "with 200 status" do
      subject(:response) { described_class.new(200, {}) }

      it "returns true" do
        expect(response).to be_success
      end
    end

    context "with 204 status" do
      subject(:response) { described_class.new(204, {}) }

      it "returns true" do
        expect(response).to be_success
      end
    end

    context "with 400 status" do
      subject(:response) { described_class.new(400, {}) }

      it "returns false" do
        expect(response).not_to be_success
      end
    end

    context "with 500 status" do
      subject(:response) { described_class.new(500, {}) }

      it "returns false" do
        expect(response).not_to be_success
      end
    end
  end

  describe "#failure?" do
    context "with successful response" do
      subject(:response) { described_class.new(200, {}) }

      it "returns false" do
        expect(response).not_to be_failure
      end
    end

    context "with failed response" do
      subject(:response) { described_class.new(400, {}) }

      it "returns true" do
        expect(response).to be_failure
      end
    end
  end

  describe "#validation_messages" do
    subject(:response) { described_class.new(200, body) }

    context "when body has no validationMessages" do
      let(:body) { {} }

      it "returns empty array" do
        expect(response.validation_messages).to eq([])
      end
    end

    context "when body contains validation messages" do
      let(:body) { { "validationMessages" => ["Message 1", "Message 2"] } }

      it "returns validation messages from body" do
        expect(response.validation_messages).to eq(["Message 1", "Message 2"])
      end
    end

    context "when body is not a hash" do
      let(:body) { "string body" }

      it "returns empty array" do
        expect(response.validation_messages).to eq([])
      end
    end
  end

  describe "#to_h" do
    subject(:response) { described_class.new(200, { data: "value" }, ["error"]) }
    let(:response_hash) { response.to_h }

    it "returns a hash representation with correct values" do
      expect(response_hash[:status_code]).to eq(200)
      expect(response_hash[:success]).to be true
      expect(response_hash[:body]).to eq({ data: "value" })
      expect(response_hash[:errors]).to eq(["error"])
      expect(response_hash[:validation_messages]).to be_an(Array)
    end
  end

  describe "#to_s" do
    context "with successful response" do
      subject(:response) { described_class.new(200, {}) }

      it "returns success message" do
        expect(response.to_s).to eq("Success (200)")
      end
    end

    context "with single error" do
      subject(:response) { described_class.new(400, {}, ["Bad Request"]) }

      it "returns failure message with error" do
        expect(response.to_s).to eq("Failure (400): Bad Request")
      end
    end

    context "with multiple errors" do
      subject(:response) { described_class.new(500, {}, ["Error 1", "Error 2"]) }

      it "returns failure message with all errors" do
        expect(response.to_s).to eq("Failure (500): Error 1, Error 2")
      end
    end
  end
end
