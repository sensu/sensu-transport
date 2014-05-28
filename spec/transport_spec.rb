require File.join(File.dirname(__FILE__), "helpers")
require "sensu/transport"
require "logger"

describe "Sensu::Transport" do
  include Helpers

  it "can load and connect to the rabbitmq transport" do
    async_wrapper do
      options = {}
      transport = Sensu::Transport.connect("rabbitmq", options)
      timer(1) do
        transport.connected?.should be_true
        async_done
      end
    end
  end

  it "can set the transport logger" do
    async_wrapper do
      logger = Logger.new(STDOUT)
      Sensu::Transport.logger = logger
      transport = Sensu::Transport.connect("rabbitmq")
      transport.logger.should eq(logger)
      transport.logger.should respond_to(:error)
      async_done
    end
  end

  it "can set the transport on_error callback" do
    async_wrapper do
      expected_error = StandardError.new("foo")
      Sensu::Transport.on_error do |error|
        error.should eq(expected_error)
        async_done
      end
      transport = Sensu::Transport.connect("rabbitmq")
      transport.on_error.call(expected_error)
    end
  end

  it "can set the transport before_reconnect callback" do
    async_wrapper do
      Sensu::Transport.before_reconnect do
        async_done
      end
      transport = Sensu::Transport.connect("rabbitmq")
      transport.before_reconnect.call
    end
  end

  it "can set the transport after_reconnect callback" do
    async_wrapper do
      Sensu::Transport.after_reconnect do
        async_done
      end
      transport = Sensu::Transport.connect("rabbitmq")
      transport.after_reconnect.call
    end
  end
end
