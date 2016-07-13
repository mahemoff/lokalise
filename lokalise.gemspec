# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lokalise/version'

Gem::Specification.new do |spec|
  spec.name          = 'lokalise'
  spec.version       = Lokalise::VERSION
  spec.authors       = ['Michael Mahemoff', 'Eden Vicary']
  spec.email         = ['michael@mahemoff.com']

  spec.summary       = 'Pull Lokalise translations'
  spec.description   = 'Download translation files from the Lokalise'
  spec.homepage      = 'https://github.com/mahemoff/lokalise'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_runtime_dependency 'byebug', '~> 8.2'
  spec.add_runtime_dependency 'excon', '~> 0.40'
  spec.add_runtime_dependency 'hashie', '~> 2'
  spec.add_runtime_dependency 'json', '~> 1.8'
  spec.add_runtime_dependency 'rubyzip', '~> 1.0'
  spec.add_runtime_dependency 'slop', '~> 4.0'
end
