require File.join(File.dirname(__FILE__), "helpers")
require "sensu/transport/redis"
require "logger"

describe "Sensu::Transport::Redis" do
  include Helpers

  before do
    @transport = Sensu::Transport::Redis.new
    @transport.logger = Logger.new(STDOUT)
    @transport.logger.level = Logger::FATAL
  end

  it "provides a transport API" do
    expect(@transport).to respond_to(:on_error, :before_reconnect, :after_reconnect,
                                     :connect, :reconnect, :connected?, :close,
                                     :publish, :subscribe, :unsubscribe,
                                     :acknowledge, :ack, :stats)
  end

  it "can publish and subscribe" do
    async_wrapper do
      @transport.connect
      callback = Proc.new do |info, message|
        expect(info).to be_kind_of(Hash)
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
          expect(info[:queued]).to eq(1)
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
          timer(1) do
            expect(@transport.connected?).to be(false)
            async_done
          end
        end
      end
    end
  end

  it "can open and close the connection immediately" do
    async_wrapper do
      @transport.connect
      @transport.close
      timer(1) do
        expect(@transport.connected?).to be(false)
        async_done
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

#  it "can fail to connect" do
#    async_wrapper do
#      @transport.connect(:port => 5555)
#      expect(@transport.connected?).to be(false)
#      async_done
#    end
#  end

  it "will throw an error if it cannot resolve a hostname" do
    async_wrapper do
      expect {
        @transport.connect(:host => "2def33c3-cfbb-4993-b5ee-08d47f6d8793")
      }.to raise_error
      async_done
    end
  end
end
