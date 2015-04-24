If you want to try a later version of jruby-kafka bump the version number in the logstash-kafka.gemspec to the desired version. Then build run the make tarball with the jruby-kafka.gem in the root of the project.  The jruby bundler should pick up the unpublished gem from the current working directory.


Build and release gem:

```
gem build logstash-kafka.gemspec
gem push logstash-kafka*.gem
```
