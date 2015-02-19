# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require 'logstash/outputs/kafka'
require 'jruby-kafka'
require 'json'

describe "outputs/kafka" do
  let (:simple_kafka_config) {{'topic_id' => 'test'}}
  let (:event) { LogStash::Event.new({'message' => 'hello', 'topic_name' => 'my_topic',
                                      '@timestamp' => LogStash::Timestamp.now}) }

  context 'when initializing' do
    it "should register" do
      output = LogStash::Plugin.lookup("output", "kafka").new(simple_kafka_config)
      expect {output.register}.to_not raise_error
    end

    it 'should populate kafka config with default values' do
      kafka = LogStash::Outputs::Kafka.new(simple_kafka_config)
      insist {kafka.broker_list} == 'localhost:9092'
      insist {kafka.topic_id} == 'test'
      insist {kafka.compression_codec} == 'none'
      insist {kafka.serializer_class} == 'kafka.serializer.StringEncoder'
      insist {kafka.partitioner_class} == 'kafka.producer.DefaultPartitioner'
      insist {kafka.producer_type} == 'sync'
    end
  end

  context 'when outputting messages' do
    it 'should send logstash event to kafka broker' do
      expect_any_instance_of(Kafka::Producer).to receive(:send_msg)
                                                     .with(simple_kafka_config['topic_id'], nil, event.to_hash.to_json)
      kafka = LogStash::Outputs::Kafka.new(simple_kafka_config)
      kafka.register
      kafka.receive(event)
    end

    it 'should support Event#sprintf placeholders in topic_id' do
      topic_field = 'topic_name'
      expect_any_instance_of(Kafka::Producer).to receive(:send_msg)
                                                     .with(event[topic_field], nil, event.to_hash.to_json)
      kafka = LogStash::Outputs::Kafka.new({'topic_id' => "%{#{topic_field}}"})
      kafka.register
      kafka.receive(event)
    end
  end
end