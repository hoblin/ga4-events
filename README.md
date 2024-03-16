# GA4::Events

A framework-agnostic Ruby implementation of Google Analytics 4 (GA4) Measurement Protocol for sending events to GA4. This gem provides a simple, reliable way to track events with features like batch sending, validation, retry logic, and debug mode.

## Features

- 🚀 **Simple API** - Easy to use with sensible defaults
- 📦 **Batch Events** - Send multiple events in a single request
- ✅ **Validation** - Validate events before sending (optional)
- 🔄 **Retry Logic** - Automatic retry with configurable attempts
- 🐛 **Debug Mode** - Test events without affecting production data
- 📝 **Configurable Logging** - Built-in logger with customization options
- 🛡️ **Silent Failures** - Fail gracefully without breaking your application
- 🔌 **Zero Dependencies** - Uses only Ruby standard library

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add ga4-events
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install ga4-events
```

## Configuration

Configure the gem in an initializer (e.g., `config/initializers/ga4.rb` for Rails):

```ruby
require "ga4/events"

GA4::Events.configure do |config|
  # Required: Your GA4 Measurement ID and API Secret
  config.measurement_id = "G-XXXXXXXXXX"  # or ENV["GA4_MEASUREMENT_ID"]
  config.api_secret = "your_api_secret"    # or ENV["GA4_API_SECRET"]

  # Optional: Configuration options with defaults shown
  config.validation_mode = false      # Use validation endpoint for server-side validation
  config.debug_mode = false           # Inject debug_mode param for DebugView
  config.validate_events = true       # Validate events before sending
  config.max_retries = 3              # Number of retry attempts
  config.retry_delay = 1              # Seconds between retries
  config.timeout = 10                 # HTTP timeout in seconds
  config.fail_silently = true         # Don't raise exceptions on errors

  # Optional: Custom logger (defaults to Logger.new($stdout))
  config.logger = Rails.logger        # Use Rails logger
  config.logger.level = Logger::INFO  # Set log level
end
```

### Environment Variables

You can use environment variables for configuration:

```bash
export GA4_MEASUREMENT_ID="G-XXXXXXXXXX"
export GA4_API_SECRET="your_api_secret"
```

## Usage

### Sending a Single Event

```ruby
# Simple event
GA4::Events.track("page_view")

# Event with parameters
GA4::Events.track("purchase", {
  transaction_id: "T12345",
  value: 99.99,
  currency: "USD",
  items: [{
    item_id: "SKU123",
    item_name: "Product Name"
  }]
})

# Event with client_id and user_id
GA4::Events.track("login", {
  method: "google"
}, client_id: "custom_client_id", user_id: "user123")
```

### Sending Batch Events

Send multiple events in a single request (more efficient):

```ruby
events = [
  { name: "page_view", params: { page_title: "Home" } },
  { name: "scroll", params: { percent_scrolled: 90 } },
  { name: "button_click", params: { button_name: "signup" } }
]

GA4::Events.track_batch(events, client_id: "client123")
```

### Using the Client Class

For more control, use the Client class directly:

```ruby
client = GA4::Events::Client.new

# Send single event
response = client.send_event("add_to_cart", {
  item_id: "SKU123",
  quantity: 2
})

# Send batch
response = client.send_batch([
  GA4::Events::Event.new("view_item", { item_id: "SKU123" }),
  GA4::Events::Event.new("add_to_cart", { item_id: "SKU123" })
])

# Check response
if response.success?
  puts "Events sent successfully!"
else
  puts "Failed: #{response.errors.join(', ')}"
end
```

### Validation Mode

Use the validation endpoint to get server-side validation feedback from Google Analytics:

```ruby
GA4::Events.configure do |config|
  config.validation_mode = true  # Uses GA4 validation endpoint
end

response = GA4::Events.track("test_event", { test_param: "value" })

# Validation mode returns validation messages
puts response.validation_messages
```

### Validation Mode

Use the validation endpoint to get server-side validation feedback from Google Analytics:

```ruby
GA4::Events.configure do |config|
  config.validation_mode = true  # Uses GA4 validation endpoint
end

response = GA4::Events.track("test_event", { test_param: "value" })

# Validation mode returns validation messages
puts response.validation_messages
```

### Debug Mode

Send events to DebugView for real-time debugging in the GA4 interface:

```ruby
GA4::Events.configure do |config|
  config.debug_mode = true  # Injects debug_mode=1 parameter
end

response = GA4::Events.track("test_event", { test_param: "value" })

# Events will appear in DebugView (note: may take 3-20 minutes)
# View at: Admin > Data display > DebugView
```

**Note:** You may need to wait 3-5 or even 20 minutes to see events in DebugView.

### Event Validation

The gem validates events according to GA4 rules:

- Event names: max 40 characters
- Parameters: max 25 per event
- Parameter names: max 40 characters
- Parameter string values: max 100 characters

```ruby
# Valid event
event = GA4::Events::Event.new("purchase", { transaction_id: "T123" })
event.valid? # => true

# Invalid event (name too long)
event = GA4::Events::Event.new("a" * 50, {})
event.valid? # => false
event.errors # => ["Event name cannot exceed 40 characters"]
```

Disable validation if needed:

```ruby
GA4::Events.configure do |config|
  config.validate_events = false
end
```

### Custom Logger

Use your own logger:

```ruby
require "logger"

custom_logger = Logger.new("log/ga4.log")
custom_logger.level = Logger::DEBUG

GA4::Events.configure do |config|
  config.logger = custom_logger
end
```

Or disable logging:

```ruby
GA4::Events.configure do |config|
  config.logger = nil
end
```

### Error Handling

By default, errors are handled silently and logged:

```ruby
# With fail_silently = true (default)
response = GA4::Events.track("test")
response.success? # => false
response.errors   # => ["Error details"]
```

Raise exceptions on errors:

```ruby
GA4::Events.configure do |config|
  config.fail_silently = false
end

begin
  GA4::Events.track("test")
rescue GA4::Events::Error => e
  puts "Error: #{e.message}"
end
```

### Retry Logic

Failed requests are automatically retried:

```ruby
GA4::Events.configure do |config|
  config.max_retries = 5    # Try up to 5 times
  config.retry_delay = 2    # Wait 2 seconds between retries
end
```

## Advanced Usage

### Client ID Generation

The gem automatically generates a UUID for `client_id` if not provided. For consistent user tracking, provide your own:

```ruby
# Use a hashed user identifier
require "digest"

client_id = Digest::SHA256.hexdigest("user_email@example.com")
GA4::Events.track("login", {}, client_id: client_id)
```

### Per-Request Configuration

Create multiple clients with different configurations:

```ruby
# Production config
prod_config = GA4::Events::Configuration.new
prod_config.measurement_id = "G-PROD"
prod_config.api_secret = "prod_secret"

# Test config
test_config = GA4::Events::Configuration.new
test_config.measurement_id = "G-TEST"
test_config.api_secret = "test_secret"
test_config.debug_mode = true

# Use different configs
prod_client = GA4::Events::Client.new(prod_config)
test_client = GA4::Events::Client.new(test_config)

prod_client.send_event("purchase", { value: 99.99 })
test_client.send_event("test_event", { test: true })
```

## Common Event Types

### E-commerce Events

```ruby
# Purchase
GA4::Events.track("purchase", {
  transaction_id: "T123",
  value: 99.99,
  currency: "USD",
  tax: 8.00,
  shipping: 5.00
})

# Add to cart
GA4::Events.track("add_to_cart", {
  currency: "USD",
  value: 49.99,
  items: [{
    item_id: "SKU123",
    item_name: "Product Name",
    price: 49.99,
    quantity: 1
  }]
})
```

### User Engagement

```ruby
# Page view
GA4::Events.track("page_view", {
  page_title: "Home",
  page_location: "https://example.com/",
  page_path: "/"
})

# User engagement
GA4::Events.track("user_engagement", {
  engagement_time_msec: 5000
})
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/the-rubies-way/ga4-events. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/the-rubies-way/ga4-events/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the GA4::Events project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/the-rubies-way/ga4-events/blob/main/CODE_OF_CONDUCT.md).
