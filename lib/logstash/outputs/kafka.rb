require 'logstash/namespace'
require 'logstash/outputs/base'

class LogStash::Outputs::Kafka < LogStash::Outputs::Base
  config_name 'kafka'
  milestone 1

  default :codec, 'json'

  config :broker_list, :validate => :string, :default => 'localhost:9092'
  config :topic_id, :validate => :string, :default => 'test'
  config :compression_codec, :validate => %w(none gzip snappy), :default => 'none'
  config :compressed_topics, :validate => :string, :default => ''
  config :request_required_acks, :validate => [-1,0,1], :default => 0

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
      :request_required_acks => @request_required_acks
    }
    @producer = Kafka::Producer.new(options)
    @producer.connect()

    @logger.info('Registering kafka producer', :topic_id => @topic_id, :broker_list => @broker_list)

    @codec.on_event do |event|
      begin
        @producer.sendMsg(@topic_id,nil,event)
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
    @codec.encode(event)
  end

end #class LogStash::Outputs::Kafka
