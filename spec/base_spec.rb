require File.join(File.dirname(__FILE__), "helpers")
require "sensu/transport/base"

describe "Sensu::Transport::Base" do
  include Helpers

  before do
    @transport = Sensu::Transport::Base.new
  end

  it "provides a transport API (noop)" do
    expect(@transport).to respond_to(:on_error, :before_reconnect, :after_reconnect,
                                     :connect, :reconnect, :connected?, :close,
                                     :publish, :subscribe, :unsubscribe,
                                     :acknowledge, :ack, :stats)
  end

  it "behaves as expected" do
    callback = Proc.new { true }
    expect(@transport.on_error(&callback)).to be_kind_of(Proc)
    expect(@transport.before_reconnect(&callback)).to be_an_instance_of(Proc)
    expect(@transport.after_reconnect(&callback)).to be_an_instance_of(Proc)
    expect(@transport.connect).to eq(nil)
    expect(@transport.connect({})).to eq(nil)
    expect(@transport.reconnect).to eq(nil)
    expect(@transport.connected?).to eq(false)
    expect(@transport.close).to eq(nil)
    expect(@transport.publish("foo", "bar", "baz")).to eq(nil)
    expect(@transport.publish("foo", "bar", "baz", {}, &callback)).to eq(true)
    expect(@transport.subscribe("foo", "bar", nil, {}, &callback)).to eq(true)
    expect(@transport.unsubscribe).to eq(nil)
    expect(@transport.unsubscribe(&callback)).to eq(true)
    expect(@transport.acknowledge({})).to eq(nil)
    expect(@transport.ack({})).to eq(nil)
    expect(@transport.acknowledge({}, &callback)).to eq(true)
    expect(@transport.ack({}, &callback)).to eq(true)
    expect(@transport.stats("foo", &callback)).to eq(true)
  end
end
