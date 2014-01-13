require 'logstash/namespace'
require 'logstash/outputs/base'
require 'jruby-kafka'

class LogStash::Outputs::Kafka < LogStash::Outputs::Base
  config_name 'kafka'
  milestone 1

  default :codec, 'plain'

  config :zk_connect, :validate => :string, :required => true
  config :broker_list, :validate => :string, :required => true
  config :topic_id, :validate => :string, :required => true

  public
  def register
    jarpath = File.join(File.dirname(__FILE__), "../../../vendor/jar/kafka*.jar")
    Dir[jarpath].each do |jar|
      require jar
    end
    options = {
        :zk_connect => @zk_connect,
        :topic_id => @topic_id,
        :broker_list => @broker_list
    }
    @producer = Kafka::Producer.new(options)
    @producer.connect()
    @logger.info('Registering kafka', :topic_id => @topic_id, :zk_connect => @zk_connect)
  end # def register

  public
  def receive(event)
    return unless output?(event)

    key = event.sprintf(@key)
    # TODO(sissel): We really should not drop an event, but historically
    # we have dropped events that fail to be converted to json.
    # TODO(sissel): Find a way to continue passing events through even
    # if they fail to convert properly.
    begin
      payload = event.to_json
    rescue Encoding::UndefinedConversionError, ArgumentError
      puts "FAILUREENCODING"
      @logger.error("Failed to convert event to JSON. Invalid UTF-8, maybe?",
                    :event => event.inspect)
      return
    end

    @producer.sendMsg(key,payload)
  end # def receive 

  public
  def teardown
    @kafka_client_queue.push(:stop_plugin)
  end

  private
  def queue_event(msg, output_queue)
    begin
      @codec.decode(msg) do |event|
        decorate(event)
        event['kafka'] = {'msg_size' => msg.bytesize, 'topic' => @topic_id, 'consumer_group' => @group_id}
        output_queue << event
      end # @codec.decode
    rescue => e # parse or event creation error
      @logger.error("Failed to create event", :message => msg, :exception => e,
                    :backtrace => e.backtrace);
    end # begin
  end # def queue_event

end #class LogStash::Inputs::Kafka
