# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "sensu-transport"
  spec.version       = "7.0.2"
  spec.authors       = ["Sean Porter"]
  spec.email         = ["portertech@gmail.com"]
  spec.summary       = "The Sensu transport abstraction library"
  spec.description   = "The Sensu transport abstraction library"
  spec.homepage      = "https://github.com/sensu/sensu-transport"
  spec.license       = "MIT"

  spec.files         = Dir.glob("lib/**/*") + %w[sensu-transport.gemspec README.md LICENSE.txt]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency("eventmachine")
  spec.add_dependency("amq-protocol", "2.0.1")
  spec.add_dependency("amqp", "1.6.0")
  spec.add_dependency("sensu-redis", ">= 1.0.0")

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sensu-logger"
end
