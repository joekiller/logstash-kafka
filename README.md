# logstash-kafka

This project implements Kafka 0.8.0 inputs and outputs for logstash.

For more info about logstash, see <http://logstash.net/>

## Dependencies

* [Apache Kafka] version 0.8.0

* [jruby-kafka] library.

[Apache Kafka]: http://kafka.apache.org/
[jruby-kafka]: https://github.com/joekiller/jruby-kafka

## Building

Because this is a plugin to Logstash, it must be built.  Luckily for you, there is a make file that handles all of this.

Most of the logic originated from logstash's make file so thank you everyone who had contributed to it to enable me to
make this easy for you.

The make file is currently configured to use JRuby version 1.7.9 and logstash version 1.3.3.

To simply build the logstash jar as is with Kafka enabled run:

    # make flatjar

To build the logstash jar with a different version of logstash do:

    # make flatjar LOGSTASH_VERSION=1.3.3

## Configuration for runtime

jruby-kafka supports nearly all the configuration options of a Kafka high level consumer but some have been left out of
this plugin simply because either it was a priority or I hadn't tested it yet.  If one isn't currently, it should be
trivial to add it via jruby-kafka and then in the logstash input or output.

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
        }
    }

### Output

    # output {
        kafka {
            :broker_list => ... # string (optional), default: "localhost:9092"
            :topic_id => ... # string (optional), default: "test"
            :compression_codec => ... # string (optional), one of ["none", "gzip", "snappy"], default: "none"
            :compressed_topics => ... # string (optional), default: ""
        }
    }

Please note on the output that the default codec is plain which will encode your messages with not only the message
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

The make file currently flattens the Kafka jar files and merges them into the uberjar.  I think this is overkill but
it is the way it is working now.  Feel free to test other ways to make this all simpler.  I need to get it to
"just work" currently so that is where we are now.
