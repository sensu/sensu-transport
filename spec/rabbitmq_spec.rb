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

  it "can acknowledge the delivery of a message" do
    async_wrapper do
      @transport.connect
      @transport.subscribe("direct", "foo", :ack => true) do |info, message|
        @transport.acknowledge(info) do
          timer(0.5) do
            async_done
          end
        end
      end
      timer(1) do
        @transport.publish("direct", "foo", "msg") do |info|
          info.should be_kind_of(Hash)
          info.should be_empty
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

  it "can use TLS", :ssl => true do
    ssl_dir = File.join(File.dirname(__FILE__), "assets", "ssl", "client")
    async_wrapper do
      @transport.connect(
        :port => 5671,
        :ssl => {
          :cert_chain_file => File.join(ssl_dir, "cert.pem"),
          :private_key_file => File.join(ssl_dir, "key.pem")
         }
      )
      timer(2) do
        @transport.connected?.should be_true
        async_done
      end
    end
  end
end
