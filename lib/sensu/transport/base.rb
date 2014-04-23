module Sensu
  module Transport
    class Error < StandardError; end

    class Base
      attr_accessor :logger

      def initialize
        @on_error = Proc.new {}
        @before_reconnect = Proc.new {}
        @after_reconnect = Proc.new {}
      end

      def on_error(&callback)
        @on_error = callback
      end

      def before_reconnect(&callback)
        @before_reconnect = callback
      end

      def after_reconnect(&callback)
        @after_reconnect = callback
      end

      def connect(options={}); end

      def connected?; end

      def close; end

      def self.connect(options={})
        options ||= Hash.new
        transport = self.new
        transport.connect(options)
        transport
      end

      def publish(type, pipe, message, options={}, &callback)
        info = {:error => nil}
        callback.call(info) if callback
      end

      def subscribe(type, pipe, funnel=nil, options={}, &callback)
        info = {}
        message = ''
        callback.call(info, message)
      end

      def unsubscribe(&callback)
        info = {}
        callback.call(info) if callback
      end

      def stats(funnel, options={}, &callback)
        info = {}
        callback.call(info)
      end
    end
  end
end
