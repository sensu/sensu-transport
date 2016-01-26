# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "sensu-transport"
  spec.version       = "3.3.0"
  spec.authors       = ["Sean Porter"]
  spec.email         = ["portertech@gmail.com"]
  spec.summary       = "The Sensu transport abstraction library"
  spec.description   = "The Sensu transport abstraction library"
  spec.homepage      = "https://github.com/sensu/sensu-transport"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency("eventmachine")
  spec.add_dependency("concurrent-ruby", "1.0.0")
  spec.add_dependency("bunny", "2.2.2")
  spec.add_dependency("em-redis-unified", ">= 1.0.0")

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "codeclimate-test-reporter" unless RUBY_VERSION < "1.9"
end
