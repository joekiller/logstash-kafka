# logstash-kafka

This project implements Kafka 0.8.1.1 inputs and outputs for logstash.

For more info about logstash, see <http://logstash.net/>

logstash-kafka is now part of the logstash core project.  It will be released with the 1.5 version of logstash.  Thank
you for your support.  My goal is to close out tickets here but for the most part, issues and problems should be
resolved via:

  * https://groups.google.com/forum/#!forum/logstash-users The logstash-users mailing list is extremely active and I 
  participate especially in Kafka troubleshooting/discussion there.
  
  * IRC: #logstash on irc.freenode.org
  
  * If you really have an issue that you can't resolve via the mailing list or IRC channel, try posting an issue to
  github.  Please make sure that issues are actually software issues, not configuration issues as those should be left
  to the mailing lists and IRC. https://github.com/elasticsearch/logstash/issues

I will keep this library up to date at least until logstash 1.5 is released.

I will continue helping with the plugin and readying for the next version of Kafka with the jruby-kafka library.

## Dependencies

* [Apache Kafka] version 0.8.1.1 

* [jruby-kafka] library.

[Apache Kafka]: http://kafka.apache.org/
[jruby-kafka]: https://github.com/joekiller/jruby-kafka

## Building

Because this is a plugin to Logstash, it must be built.  Luckily for you, there is a make file that handles all of this.

Most of the logic originated from logstash's make file so thank you everyone who had contributed to it to enable me to
make this easy for you.

The make file is currently configured to use JRuby version 1.7.11, logstash version 1.4.0, kafka version 0.8.1, and scala version 2.8.0.

To simply build the logstash jar as is with Kafka enabled run:

    # make tarball

To build the logstash jar with a different version of logstash do:

    # make tarball LOGSTASH_VERSION=1.4.0

To build with a different version of Kafka:

    # make tarball KAFKA_VERSION=0.8.0

To build with a different version of Scala:

    # make tarball SCALA_VERSION=2.9.2

## Configuration for runtime

jruby-kafka supports nearly all the configuration options of a Kafka high level consumer but some have been left out of
this plugin simply because either it was a priority or I hadn't tested it yet.  If one isn't currently, it should be
trivial to add it via jruby-kafka and then in the logstash input or output.

## Running

You should run this version of logstash the same as you would the normal logstash with:

    # bin/logstash agent -f logstash.conf

Contributed plugins can also still be installed using:

    # bin/plugin install contrib

### Input

See http://kafka.apache.org/documentation.html#consumerconfigs for details about the Kafka consumer options.

    # input {
        kafka {
            zk_connect => ... # string (optional), default: "localhost:2181"
            group_id => ... # string (optional), default: "logstash"
            topic_id => ... # string (optional), default: "test"
            reset_beginning => ... # boolean (optional), default: false
            consumer_threads => ... # number (optional), default: 1
            queue_size => ... # number (optional), default: 20
            rebalance_max_retries => ... # number (optional), default: 4
            rebalance_backoff_ms => ... # number (optional), default:  2000
            consumer_timeout_ms => ... # number (optional), default: -1
            consumer_restart_on_error => ... # boolean (optional), default: true
            consumer_restart_sleep_ms => ... # number (optional), default: 0
            decorate_events => ... # boolean (optional), default: true
            consumer_id => ... # string (optional) default: nil
            fetch_message_max_bytes => ... # number (optional) default: 1048576
        }
    }

### Output

See http://kafka.apache.org/documentation.html#producerconfigs for details about the Kafka producer options.

    # output {
        kafka {
            broker_list => ... # string (optional), default: "localhost:9092"
            topic_id => ... # string (optional), default: "test"
            compression_codec => ... # string (optional), one of ["none", "gzip", "snappy"], default: "none"
            compressed_topics => ... # string (optional), default: ""
            request_required_acks => ... # number (optional), one of [-1, 0, 1], default: 0
            serializer_class => ... # string, (optional) default: "kafka.serializer.StringEncoder"
            partitioner_class => ... # string (optional) default: "kafka.producer.DefaultPartitioner"
            request_timeout_ms => ... # number (optional) default: 10000
            producer_type => ... # string (optional), one of ["sync", "async"] default => 'sync'
            key_serializer_class => ... # string (optional) default: nil
            message_send_max_retries => ... # number (optional) default: 3
            retry_backoff_ms => ... # number (optional) default: 100
            topic_metadata_refresh_interval_ms => ... # number (optional) default: 600 * 1000
            queue_buffering_max_ms => ... # number (optional) default: 5000
            queue_buffering_max_messages => ... # number (optional) default: 10000
            queue_enqueue_timeout_ms => ... # number (optional) default: -1
            batch_num_messages => ... # number (optional) default: 200
            send_buffer_bytes => ... # number (optional) default: 100 * 1024
            client_id => ... # string (optional) default: ""
        }
    }

The default codec is json for input and outputs.  If you select a codec of plain, logstash will encode your messages with not only the message
but also with a timestamp and hostname.  If you do not want anything but your message passing through, you should make
the output configuration something like:

    # output {
        kafka {
            codec => plain {
                format => "%{message}"
            }
        }
    }
    
## Manual Install

Those who wish to use this plugin in an existing Logstash 1.4.0+ installation can follow these instructions to integrate the plugin into their Logstash system.

 1. Download Logstash and extract as normal.  You should have a directory named `./logstash-1.4.0`.
 2. Download the Kafka binaries (0.8.1) with the Scala version of your choice (2.8.0) and extract as normal.  You should have a directory named `./kafka_2.8.0-0.8.1`.
 3. Download logstash-kafka v0.4.2 from [releases](https://github.com/joekiller/logstash-kafka/releases) and extract as normal.  You should have a directory named `./logstash-kafka-0.4.2`.
 3. Copy all jar files from `./kafka_2.8.0-0.8.1/libs` to `./logstash-1.4.0/vendor/jar/kafka_2.8.0-0.8.1/libs`.  You will need to make the `kafka_2.8.0-0.8.1` directory.
 4. From the logstash-kafka project, copy all the files in `./logstash-kafka/lib` to `./logstash-1.4.0/lib`.
 5. From the `./logstash-1.4.0` directory you need to run logstash-kafka's gembag.rb script to install the jruby-kafka library to the logstash's gemset: `GEM_HOME=vendor/bundle/jruby/1.9 GEM_PATH= java -jar vendor/jar/jruby-complete-1.7.11.jar --1.9 ../logstash-kafka-0.4.2/gembag.rb ../logstash-kafka-0.4.2/logstash-kafka.gemspec`
 6. You should be able to run logstash with the logstash-kafka plugin now. `bin/logstash agent -f logstash.conf`. 

## Testing

There are no tests are the current time.  Please feel free to submit a pull request.

## Notes

The make file is updated to work with Logstash 1.4.0+.  DEB package building isn't supported at this time.

To build an rpm

    # make package

Installing the resulting rpm after installing logstash from the elasticsearch repo will copy the kafka plugin and dependencies into `/opt/logstash`.
