# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name          =  'logstash-kafka'
  s.version       = '0.8.1'
  s.platform      = 'java'
  s.authors       = ['Joseph Lawson']
  s.email         = ['joe@joekiller.com']
  s.description   = 'Kafka input and output plugins for Logstash'
  s.summary       = 'Provides input and output plugin functionality for Logstash 1.4.X'
  s.homepage      = 'https://github.com/joekiller/logstash-kafka'
  s.license       = 'Apache 2.0'
  s.platform      = 'java'
  s.require_paths = [ 'lib' ]

  s.files = Dir[ 'lib/**/*.rb']

  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  s.add_runtime_dependency 'jruby-kafka', ['~> 1.4.0']
end
