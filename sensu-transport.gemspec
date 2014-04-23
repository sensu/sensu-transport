# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "sensu-transport"
  spec.version       = "0.0.1"
  spec.authors       = ["Sean Porter"]
  spec.email         = ["portertech@gmail.com"]
  spec.summary       = %q{TODO: Write a short summary. Required.}
  spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency('eventmachine', '1.0.3')
  spec.add_dependency('amq-protocol', '1.2.0')
  spec.add_dependency('amq-client', '1.0.2')
  spec.add_dependency('amqp', '1.0.0')

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
