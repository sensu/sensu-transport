require File.join(File.dirname(__FILE__), "helpers")
require "sensu/transport/base"

describe "Sensu::Transport::Base" do
  include Helpers

  before do
    @base = Sensu::Transport::Base.new
  end

  it "Provides a transport API (noop)" do
    Sensu::Transport::Base.should respond_to(:connect)
    @base.should respond_to(:on_error, :before_reconnect, :after_reconnect,
                            :connect, :connected?, :close,
                            :publish, :subscribe, :unsubscribe)
  end
end
