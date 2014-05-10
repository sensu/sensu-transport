module Sensu
  module Transport
    class Error < StandardError; end

    class Base
      # @!attribute [rw] logger
      #   @return [Logger] the Sensu logger object.
      attr_accessor :logger

      def initialize
        @on_error = Proc.new {}
        @before_reconnect = Proc.new {}
        @after_reconnect = Proc.new {}
      end

      # Sets the error callback.
      #
      # @param callback [Proc] called in the event of a transport
      #   error, the exception object should be passed as a parameter.
      # @return [Proc] the error callback.
      def on_error(&callback)
        @on_error = callback
      end

      # Sets the before reconnect callback.
      #
      # @param callback [Proc] called before attempting to reconnect
      #   to the transport.
      # @return [Proc] the before reconnect callback.
      def before_reconnect(&callback)
        @before_reconnect = callback
      end

      # Sets the after reconnect callback.
      #
      # @param callback [Proc] called after reconnecting to the
      #   transport.
      # @return [Proc] the after reconnect callback.
      def after_reconnect(&callback)
        @after_reconnect = callback
      end

      # Transport connection setup.
      #
      # @param options [Hash, String]
      def connect(options={}); end

      # Indicates if connected to the transport.
      #
      # @return [TrueClass, FalseClass]
      def connected?
        false
      end

      # Close the transport connection.
      def close; end

      # Publish a message to the transport.
      #
      # @param type [Symbol] the transport pipe type, possible values
      #   are: :direct and :fanout.
      # @param pipe [String] the transport pipe name.
      # @param message [String] the message to be published to the transport.
      # @param options [Hash] the options to publish the message with.
      # @yield [info] passes publish info to an optional callback/block.
      # @yieldparam info [Hash] contains publish information, which
      #   may contain an error object.
      def publish(type, pipe, message, options={}, &callback)
        info = {:error => nil}
        callback.call(info) if callback
      end

      # Subscribe to a transport pipe and/or funnel.
      #
      # @param type [Symbol] the transport pipe type, possible values
      #   are: :direct and :fanout.
      # @param pipe [String] the transport pipe name.
      # @param funnel [String] the transport funnel, which may be
      #   connected to multiple pipes.
      # @param options [Hash] the options to consume messages with.
      # @yield [info, message] passes message info and content to
      #   the consumer callback/block.
      # @yieldparam info [Hash] contains message information.
      # @yieldparam message [String] message.
      def subscribe(type, pipe, funnel=nil, options={}, &callback)
        info = {}
        message = ''
        callback.call(info, message)
      end

      # Unsubscribe from all transport pipes and/or funnels.
      #
      # @yield [info] passes info to an optional callback/block.
      # @yieldparam info [Hash] contains unsubscribe information.
      def unsubscribe(&callback)
        info = {}
        callback.call(info) if callback
      end

      # Acknowledge the delivery of a message from the transport.
      #
      # @param info [Hash] message information, eg. contains its id.
      # @yield [info] passes acknowledgment info to an optional callback/block.
      def acknowledge(info, &callback)
        callback.call(info) if callback
      end

      # Alias for acknowledge()
      def ack(*args, &callback)
        acknowledge(*args, &callback)
      end

      # Transport funnel stats, such as message and consumer counts.
      #
      # @param funnel [String] the transport funnel to get stats for.
      # @param options [Hash] the options to get funnel stats with.
      def stats(funnel, options={}, &callback)
        info = {}
        callback.call(info)
      end

      # Discover available transports (Subclasses)
      def self.descendants
        ObjectSpace.each_object(Class).select do |klass|
          klass < self
        end
      end
    end
  end
end
