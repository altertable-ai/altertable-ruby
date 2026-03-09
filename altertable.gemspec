# frozen_string_literal: true

require_relative "lib/altertable/version"

Gem::Specification.new do |spec|
  spec.name          = "altertable"
  spec.version       = Altertable::VERSION
  spec.authors       = ["Altertable"]
  spec.email         = ["support@api.altertable.ai"]

  spec.summary       = "Altertable Product Analytics Ruby SDK"
  spec.description   = "Official Ruby client for Altertable Product Analytics"
  spec.homepage      = "https://github.com/altertable-ai/altertable-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/altertable-ai/altertable-ruby/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.add_development_dependency "rubocop-performance", "~> 1.0"
  spec.add_development_dependency "rubocop-rspec", "~> 2.0"
  spec.add_development_dependency "testcontainers"
  spec.add_development_dependency "rbs"

  # Optional adapter support (development only)
  spec.add_development_dependency "faraday", "~> 2.0"
  spec.add_development_dependency "faraday-retry"
  spec.add_development_dependency "faraday-net_http"
  spec.add_development_dependency "httpx"
end
