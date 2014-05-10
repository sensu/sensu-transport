require File.join(File.dirname(__FILE__), "helpers")
require "sensu/transport/base"

describe "Sensu::Transport::Base" do
  include Helpers

  before do
    @transport = Sensu::Transport::Base.new
  end

  it "provides a transport API (noop)" do
    @transport.should respond_to(:on_error, :before_reconnect, :after_reconnect,
                                 :connect, :connected?, :close,
                                 :publish, :subscribe, :unsubscribe, :stats)
  end

  it "behaves as expected" do
    callback = Proc.new { true }
    @transport.on_error(&callback).should be_an_instance_of(Proc)
    @transport.before_reconnect(&callback).should be_an_instance_of(Proc)
    @transport.after_reconnect(&callback).should be_an_instance_of(Proc)
    @transport.connect.should eq(nil)
    @transport.connect({}).should eq(nil)
    @transport.connected?.should eq(false)
    @transport.close.should eq(nil)
    @transport.publish("foo", "bar", "baz").should eq(nil)
    @transport.publish("foo", "bar", "baz", {}, &callback).should eq(true)
    @transport.subscribe("foo", "bar", nil, {}, &callback).should eq(true)
    @transport.unsubscribe.should eq(nil)
    @transport.unsubscribe(&callback).should eq(true)
    @transport.acknowledge({}).should eq(nil)
    @transport.ack({}).should eq(nil)
    @transport.acknowledge({}, &callback).should eq(true)
    @transport.ack({}, &callback).should eq(true)
    @transport.stats("foo", &callback).should eq(true)
  end
end
