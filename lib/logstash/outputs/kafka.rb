require 'logstash/namespace'
require 'logstash/outputs/base'

class LogStash::Outputs::Kafka < LogStash::Outputs::Base
  config_name 'kafka'
  milestone 1

  default :codec, 'json'

  config :broker_list, :validate => :string, :default => 'localhost:9092'
  config :topic_id, :validate => :string, :default => 'test'
  config :compression_codec, :validate => %w( none gzip snappy ), :default => 'none'
  config :compressed_topics, :validate => :string, :default => ''
  config :request_required_acks, :validate => [-1,0,1], :default => 0
  config :serializer_class, :validate => :string, :default => 'kafka.serializer.StringEncoder'
  config :partitioner_class, :validate => :string, :default => 'kafka.producer.DefaultPartitioner'
  config :request_timeout_ms, :validate => :number, :default => 10000
  config :producer_type, :validate => %w( sync async ), :default => 'sync'
  config :key_serializer_class, :validate => :string, :default => 'kafka.serializer.StringEncoder'
  config :message_send_max_retries, :validate => :number, :default => 3
  config :retry_backoff_ms, :validate => :number, :default => 100
  config :topic_metadata_refresh_interval_ms, :validate => :number, :default => 600 * 1000
  config :queue_buffering_max_ms, :validate => :number, :default => 5000
  config :queue_buffering_max_messages, :validate => :number, :default => 10000
  config :queue_enqueue_timeout_ms, :validate => :number, :default => -1
  config :batch_num_messages, :validate => :number, :default => 200
  config :send_buffer_bytes, :validate => :number, :default => 100 * 1024
  config :client_id, :validate => :string, :default => ""
  
  config :partition_key_format, :validate => :string, :default => nil

  public
  def register
    jarpath = File.join(File.dirname(__FILE__), "../../../vendor/jar/kafka*/libs/*.jar")
    Dir[jarpath].each do |jar|
      require jar
    end
    require 'jruby-kafka'
    options = {
      :topic_id => @topic_id,
      :broker_list => @broker_list,
      :compression_codec => @compression_codec,
      :compressed_topics => @compressed_topics,
      :request_required_acks => @request_required_acks,
      :serializer_class => @serializer_class,
      :partitioner_class => @partitioner_class,
      :request_timeout_ms => @request_timeout_ms,
      :producer_type => @producer_type,
      :key_serializer_class => @key_serializer_class,
      :message_send_max_retries => @message_send_max_retries,
      :retry_backoff_ms => @retry_backoff_ms,
      :topic_metadata_refresh_interval_ms => @topic_metadata_refresh_interval_ms,
      :queue_buffering_max_ms => @queue_buffering_max_ms,
      :queue_buffering_max_messages => @queue_buffering_max_messages,
      :queue_enqueue_timeout_ms => @queue_enqueue_timeout_ms,
      :batch_num_messages => @batch_num_messages,
      :send_buffer_bytes => @send_buffer_bytes,
      :client_id => @client_id,
      :partition_key_format => @partition_key_format
    }
    @producer = Kafka::Producer.new(options)
    @producer.connect()

    @logger.info('Registering kafka producer', :topic_id => @topic_id, :broker_list => @broker_list)

    @codec.on_event do |event|
      begin
        @producer.sendMsg(@topic_id, @partition_key, event)
      rescue LogStash::ShutdownSignal
        @logger.info('Kafka producer got shutdown signal')
      rescue => e
        @logger.warn('kafka producer threw exception, restarting',
                     :exception => e)
      end
    end
  end # def register

  def receive(event)
    return unless output?(event)
    if event == LogStash::SHUTDOWN
      finished
      return
    end
    @partition_key = if @partition_key_format.nil? then nil else event.sprintf(@partition_key_format) end
    @codec.encode(event)
    @partition_key = nil
  end

end #class LogStash::Outputs::Kafka
