require File.join(File.dirname(__FILE__), "helpers")
require "sensu/transport/rabbitmq"
require "sensu/logger"

describe "Sensu::Transport::RabbitMQ" do
  include Helpers

  before do
    @transport = Sensu::Transport::RabbitMQ.new
    @transport.logger = Sensu::Logger.get(:log_level => :fatal)
  end

  it "provides a transport API" do
    expect(@transport).to respond_to(:on_error, :before_reconnect, :after_reconnect,
                                     :connect, :reconnect, :connected?, :close,
                                     :publish, :subscribe, :unsubscribe,
                                     :acknowledge, :ack, :stats)
  end

  it "can open a connection using a hostname", :dns => true do
    async_wrapper do
      @transport.connect(:host => "localhost")
      timer(1) do
        expect(@transport.connected?).to be(true)
        async_done
      end
    end
  end

  it "can publish and subscribe" do
    async_wrapper do
      @transport.connect
      callback = Proc.new do |message|
        expect(message).to eq("msg")
        timer(0.5) do
          async_done
        end
      end
      @transport.subscribe("direct", "foo", "baz", {}, &callback)
      @transport.subscribe("direct", "bar", "baz", {}, &callback)
      timer(1) do
        @transport.publish("direct", "foo", "msg") do |info|
          expect(info).to be_kind_of(Hash)
          expect(info).to be_empty
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
          expect(@transport.connected?).to be(false)
          async_done
        end
      end
    end
  end

  it "can open and close the connection immediately" do
    async_wrapper do
      @transport.connect
      @transport.close
      expect(@transport.connected?).to be(false)
      EM.next_tick do
        expect(@transport.connected?).to be(false)
        timer(1) do
          expect(@transport.connected?).to be(false)
          async_done
        end
      end
    end
  end

  it "can acknowledge the delivery of a message" do
    async_wrapper do
      @transport.connect
      @transport.subscribe("direct", "foo", "", :ack => true) do |info, message|
        @transport.acknowledge(info) do
          timer(0.5) do
            async_done
          end
        end
      end
      timer(1) do
        @transport.publish("direct", "foo", "msg") do |info|
          expect(info).to be_kind_of(Hash)
          expect(info).to be_empty
        end
      end
    end
  end

  it "can get queue stats, message and consumer counts" do
    async_wrapper do
      @transport.connect
      @transport.stats("bar") do |info|
        expect(info).to be_kind_of(Hash)
        expect(info[:messages]).to eq(0)
        expect(info[:consumers]).to eq(0)
        async_done
      end
    end
  end

  it "can fail to connect" do
    async_wrapper do
      @transport.connect(:port => 5555)
      expect(@transport.connected?).to be(false)
      async_done
    end
  end

  it "will throw an error if it cannot resolve a hostname" do
    async_wrapper do
      expected_error_class = case RUBY_PLATFORM
      when "java"
        Java::JavaNioChannels::UnresolvedAddressException
      else
        EventMachine::ConnectionError
      end
      expect {
        @transport.connect(:host => "2def33c3-cfbb-4993-b5ee-08d47f6d8793")
      }.to raise_error(expected_error_class)
      async_done
    end
  end

  it "can be configured for multiple brokers" do
    async_wrapper do
      @transport.connect([{:port => 5672}, {:port => 5672}])
      timer(2) do
        expect(@transport.connected?).to be(true)
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
        expect(@transport.connected?).to be(true)
        async_done
      end
    end
  end
end
