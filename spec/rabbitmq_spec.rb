require File.join(File.dirname(__FILE__), "helpers")
require "sensu/transport/rabbitmq"

describe "Sensu::Transport::RabbitMQ" do
  include Helpers

  before do
    @transport = Sensu::Transport::RabbitMQ.new
  end

  it "provides a transport API" do
    Sensu::Transport::RabbitMQ.should respond_to(:connect)
    @transport.should respond_to(:on_error, :before_reconnect, :after_reconnect,
                                 :connect, :connected?, :close,
                                 :publish, :subscribe, :unsubscribe)
  end

  it "can publish and subscribe" do
    async_wrapper do
      @transport.connect
      callback = Proc.new do |message|
        message.should eq("msg")
        timer(0.5) do
          async_done
        end
      end
      @transport.subscribe("direct", "foo", "baz", {}, &callback)
      @transport.subscribe("direct", "bar", "baz", {}, &callback)
      timer(1) do
        @transport.publish("direct", "foo", "msg") do |info|
          info.should be_kind_of(Hash)
          info.should be_empty
        end
      end
    end
  end

  it "can unsubscribe from queues and close the connection" do
    async_wrapper do
      @transport.connect
      @transport.subscribe("direct", "bar") do |info, message|
        true
      end
      timer(1) do
        @transport.unsubscribe do
          @transport.close
          async_done
        end
      end
    end
  end

  it "can get queue stats, message and consumer counts" do
    async_wrapper do
      @transport.connect
      @transport.stats("bar") do |info|
        info.should be_kind_of(Hash)
        info[:messages].should eq(0)
        info[:consumers].should eq(0)
        async_done
      end
    end
  end
end
