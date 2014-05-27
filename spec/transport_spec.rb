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
end
