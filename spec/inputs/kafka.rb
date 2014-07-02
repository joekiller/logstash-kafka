# encoding: utf-8

require 'rspec'
require 'insist'
require 'logstash/namespace'
require 'logstash/inputs/kafka'
require 'logstash/errors'

describe LogStash::Inputs::Kafka do

  it 'should populate kafka config with default values' do
    kafka = LogStash::Inputs::Kafka.new
    insist {kafka.zk_connect} == "localhost:2181"
    insist {kafka.topic_id} == "test"
    insist {kafka.group_id} == "logstash"
    insist {kafka.reset_beginning} == false
  end

  it "should load register and load kafka jars without errors" do
    kafka = LogStash::Inputs::Kafka.new
    kafka.register
  end

  it "should retrieve event from kafka" do
    # Extend class to control behavior
    class LogStash::Inputs::TestKafka < LogStash::Inputs::Kafka
      milestone 1
      private
      def queue_event(msg, output_queue)
        super(msg, output_queue)
        # need to raise exception here to stop the infinite loop
        raise LogStash::ShutdownSignal
      end
    end

    kafka = LogStash::Inputs::TestKafka.new
    kafka.register

    class Kafka::Group
      public
      def run(a_numThreads, a_queue)
        a_queue << "Kafka message"
      end
    end

    logstash_queue = Queue.new
    kafka.run logstash_queue
    e = logstash_queue.pop
    insist { e["message"] } == "Kafka message"
    insist { e["kafka"] } == {"msg_size"=>13, "topic"=>"test", "consumer_group"=>"logstash"}
  end
end
