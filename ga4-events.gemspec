# frozen_string_literal: true

# to load all /lib files
$LOAD_PATH.push File.expand_path("lib", __dir__)

require_relative "lib/ga4/events/version"

Gem::Specification.new do |spec|
  spec.name = "ga4-events"
  spec.version = GA4::Events::VERSION
  spec.authors = ["loqimean"]
  spec.email = ["vanuha277@gmail.com"]

  spec.summary = "Framework-agnostic Ruby implementation of Google Analytics 4 Measurement Protocol"
  spec.description = "A simple, reliable Ruby gem for sending events to Google Analytics 4 (GA4) using the Measurement Protocol. Features include batch sending, event validation, retry logic, debug mode, and configurable logging. Works with any Ruby application - no framework dependencies required."
  spec.homepage = "https://github.com/the-rubies-way/ga4-events"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/the-rubies-way/ga4-events"
  spec.metadata["changelog_uri"] = "https://github.com/the-rubies-way/ga4-events/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/the-rubies-way/ga4-events/issues"
  spec.metadata["documentation_uri"] = "https://github.com/the-rubies-way/ga4-events/blob/main/README.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard", "~> 1.3"
  spec.add_development_dependency "vcr", "~> 6.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "irb"
  spec.add_development_dependency "simplecov"
end
