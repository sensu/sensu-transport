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
        expect(transport.connected?).to be(true)
        async_done
      end
    end
  end

  it "can set the transport logger" do
    async_wrapper do
      logger = Logger.new(STDOUT)
      logger.level = Logger::ERROR
      Sensu::Transport.logger = logger
      transport = Sensu::Transport.connect("rabbitmq")
      expect(transport.logger).to eq(logger)
      expect(transport.logger).to respond_to(:error)
      async_done
    end
  end
end
