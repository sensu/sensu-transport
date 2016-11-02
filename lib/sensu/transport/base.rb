require "eventmachine"
require "ipaddr"
require "socket"

module Sensu
  module Transport
    class Error < StandardError; end

    class Base
      # Transports are deferrable objects. This is to enable callbacks
      # to be called in the event the transport calls `succeed()` to
      # indicate that it has initialized and connected successfully.
      include EM::Deferrable

      # @!attribute [rw] logger
      #   @return [Logger] the Sensu logger object.
      attr_accessor :logger

      def initialize
        @on_error = Proc.new {}
        @before_reconnect = Proc.new {}
        @after_reconnect = Proc.new {}
      end

      # Set the error callback.
      #
      # @param callback [Proc] called in the event of a transport
      #   error, the exception object should be passed as a parameter.
      # @return [Proc] the error callback.
      def on_error(&callback)
        @on_error = callback
      end

      # Set the before reconnect callback.
      #
      # @param callback [Proc] called before attempting to reconnect
      #   to the transport.
      # @return [Proc] the before reconnect callback.
      def before_reconnect(&callback)
        @before_reconnect = callback
      end

      # Set the after reconnect callback.
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

      # Reconnect to the transport.
      #
      # @param force [Boolean] the reconnect.
      def reconnect(force=false); end

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
      #   may contain an error object (:error).
      def publish(type, pipe, message, options={})
        info = {:error => nil}
        yield(info) if block_given?
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
      def subscribe(type, pipe, funnel=nil, options={})
        info = {}
        message = ''
        yield(info, message)
      end

      # Unsubscribe from all transport pipes and/or funnels.
      #
      # @yield [info] passes info to an optional callback/block.
      # @yieldparam info [Hash] contains unsubscribe information.
      def unsubscribe
        info = {}
        yield(info) if block_given?
      end

      # Acknowledge the delivery of a message from the transport.
      #
      # @param info [Hash] message information, eg. contains its id.
      # @yield [info] passes acknowledgment info to an optional callback/block.
      def acknowledge(info)
        yield(info) if block_given?
      end

      # Alias for acknowledge(). This should be superseded by a proper
      # alias via alias_method in the transport class.
      def ack(*args, &callback)
        acknowledge(*args, &callback)
      end

      # Transport funnel stats, such as message and consumer counts.
      #
      # @param funnel [String] the transport funnel to get stats for.
      # @param options [Hash] the options to get funnel stats with.
      # @yield [info] passes funnel stats a callback/block.
      # @yieldparam info [Hash] contains funnel stats.
      def stats(funnel, options={})
        info = {}
        yield(info) if block_given?
      end

      # Determine if a host is an IP address (or DNS hostname).
      #
      # @param host [String]
      # @return [TrueClass, FalseClass]
      def ip_address?(host)
        begin
          ip_address = IPAddr.new(host)
          ip_address.ipv4? || ip_address.ipv6?
        rescue IPAddr::InvalidAddressError
          false
        end
      end

      # Resolve a hostname to an IP address for a host. This method
      # will return `nil` to the provided callback when the hostname
      # cannot be resolved to an IP address.
      #
      # @param host [String]
      # @param callback [Proc] called with the result of the DNS
      #   query (IP address).
      def resolve_hostname(host, &callback)
        resolve = Proc.new do
          begin
            flags = Socket::AI_NUMERICSERV | Socket::AI_ADDRCONFIG
            info = Socket.getaddrinfo(host, nil, Socket::AF_UNSPEC, nil, nil, flags).first
            info.nil? ? nil : info[2]
          rescue => error
            @logger.error("transport connection error", {
              :reason => "unable to resolve hostname",
              :error => error.to_s
            }) if @logger
            nil
          end
        end
        EM.defer(resolve, callback)
      end

      # Resolve a hostname to an IP address for a host. This method
      # will return the provided host to the provided callback if it
      # is already an IP address. This method will return `nil` to the
      # provided callback when the hostname cannot be resolved to an
      # IP address.
      #
      # @param host [String]
      # @param callback [Proc] called with the result of the DNS
      #   query (IP address).
      def resolve_host(host, &callback)
        if ip_address?(host)
          yield host
        else
          resolve_hostname(host, &callback)
        end
      end

      # Discover available transports (Subclasses)
      def self.descendants
        ObjectSpace.each_object(Class).select do |klass|
          klass < self
        end
      end

      private

      # Catch transport errors and call the on_error callback,
      # providing it with the error object as an argument. This method
      # is intended to be applied where necessary, not to be confused
      # with a catch-all. Not all transports will need this.
      #
      # @yield [] callback/block to execute within a rescue block to
      #   catch transport errors.
      def catch_errors
        begin
          yield
        rescue => error
          @on_error.call(error)
        end
      end
    end
  end
end
