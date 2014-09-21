# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name	= "logstash-kafka"
  if RUBY_PLATFORM == 'java'
    gem.add_runtime_dependency "jruby-kafka", [">=0.1.3"]                      #(Apache 2.0 license)
  end
end
