## [Unreleased]

### [0.1.0] - Initial release!

- Framework-agnostic design - works with any Ruby application
- `GA4::Events::Client` class for sending events to GA4
- `GA4::Events::Event` class with built-in validation
- `GA4::Events::Response` class for handling API responses
- Batch event sending support (send multiple events in one request)
- Event validation according to GA4 rules (configurable)
- Automatic retry logic with configurable attempts and delays
- Debug mode using GA4 debug endpoint for testing
- Configurable logging with custom logger support
- Silent failure mode (fail_silently option)
- Timeout configuration for HTTP requests
- Convenience methods: `GA4::Events.track` and `track_batch`
- Comprehensive RSpec test suite with WebMock
- Detailed README with usage examples and best practices
