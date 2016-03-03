Gem::Specification.new do |s|
  s.authors       = ['Michael Mahemoff', 'Eden Vicary']
  s.date          = '2015-06-30'
  s.description   = 'Download translation files from the Lokali.se'
  s.email         = 'michael@mahemoff.com'
  s.executables   << 'lokalise'
  s.homepage      = 'https://github.com/mahemoff/lokalise'
  s.license       = 'MIT'
  s.name          = 'lokalise-pull'
  s.summary       = 'Pull Lokali.se translations'
  s.version       = '1.0.0'

  s.add_runtime_dependency 'byebug', '~> 8.2'
  s.add_runtime_dependency 'excon', '~> 0.40'
  s.add_runtime_dependency 'fileutils', '~> 0.7'
  s.add_runtime_dependency 'hashie', '~> 3.4'
  s.add_runtime_dependency 'json', '~> 1.8'
  s.add_runtime_dependency 'slop', '~> 4.0'
  s.add_runtime_dependency 'zip', '~> 2.0'
end
