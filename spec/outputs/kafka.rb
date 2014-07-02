# encoding: utf-8

require 'rspec'
require 'insist'
require 'logstash/namespace'
require 'logstash/outputs/kafka'
require 'logstash/errors'

describe LogStash::Outputs::Kafka do

  it 'should populate kafka config with default values' do
    kafka = LogStash::Outputs::Kafka.new
    insist {kafka.broker_list} == "localhost:9092"
    insist {kafka.topic_id} == "test"
    insist {kafka.compression_codec} == "none"
    insist {kafka.serializer_class} == "kafka.serializer.StringEncoder"
    insist {kafka.partitioner_class} == "kafka.producer.DefaultPartitioner"
    insist {kafka.producer_type} == "sync"
  end

  it "should load register and load kafka jars without errors" do
    kafka = LogStash::Outputs::Kafka.new
    kafka.register
  end

  it "should send logstash event to kafka broker" do
    expect_any_instance_of(Kafka::Producer)
    .to receive(:sendMsg)
        .with("test", nil, "{\"message\":\"hello world\",\"host\":\"test\",\"@timestamp\":\"2014-07-01T17:08:12.544-07:00\",\"@version\":\"1\"}")
    e = LogStash::Event.new({"message" => "hello world", "host" => "test", "@timestamp" => "2014-07-01T17:08:12.544-07:00"})
    kafka = LogStash::Outputs::Kafka.new
    kafka.register
    kafka.receive(e)
  end

end