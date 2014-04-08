# logstash-kafka

This project implements Kafka 0.8.1 inputs and outputs for logstash.

For more info about logstash, see <http://logstash.net/>

## Dependencies

* [Apache Kafka] version 0.8.1 

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
        }
    }

### Output

    # output {
        kafka {
            :broker_list => ... # string (optional), default: "localhost:9092"
            :topic_id => ... # string (optional), default: "test"
            :compression_codec => ... # string (optional), one of ["none", "gzip", "snappy"], default: "none"
            :compressed_topics => ... # string (optional), default: ""
            :request_required_acks => ... # number (optional), one of [-1, 0, 1], default: 0
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

## Testing

There are no tests are the current time.  Please feel free to submit a pull request.

## Notes

The make file is updated to work with Logstash 1.4.0+.  RPM and DEB package building isn't supported at this time.
