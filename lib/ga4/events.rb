# frozen_string_literal: true

require "net/http"
require "json"
require "securerandom"
require "logger"

module GA4
  module Events
    class Error < StandardError; end
    class ConfigurationError < Error; end
    class ValidationError < Error; end

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      # Convenience method to send a single event
      def track(name, params = {}, client_id: nil, user_id: nil)
        client = Client.new

        client.send_event(name, params, client_id: client_id, user_id: user_id)
      end

      # Convenience method to send batch events
      def track_batch(events, client_id: nil, user_id: nil)
        client = Client.new

        client.send_batch(events, client_id: client_id, user_id: user_id)
      end

      def reset_configuration!
        @configuration = Configuration.new
      end
    end
  end
end

Dir[File.join(__dir__, "events/**/*.rb")].sort.each { |file| require file }
