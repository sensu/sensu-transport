gem "nats", "0.8.2"

require "set"
require "nats/client"

require File.join(File.dirname(__FILE__), "base")

module Sensu
  module Transport
    class NATS < Base
      # NATS connection setup. The deferred status is set to
      # `:succeeded` (via `succeed()`) once the connection has been
      # established.
      #
      # @param options [Hash, String]
      def connect(options={})
        reset
        start(options)
      end

      # Reconnect to NATS
      #
      # @param force [Boolean] the reconnect.
      def reconnect(force=false)
        @connection.schedule_reconnect
      end

      # Indicates if connected to NATS.
      #
      # @return [TrueClass, FalseClass]
      def connected?
        @connection.connected?
      end

      # Close the NATS connection.
      def close
        @connection.close
      end

      # Publish a message to NATS.
      #
      # @param type [Symbol] the NATS exchange type, possible
      #   values are: :direct and :fanout.
      # @param pipe [String] the NATS exchange name.
      # @param message [String] the message to be published to
      #   NATS.
      # @param options [Hash] the options to publish the message with.
      # @yield [info] passes publish info to an optional
      #   callback/block.
      # @yieldparam info [Hash] contains publish information.
      def publish(type, pipe, message, options={}, &callback)
        @connection.publish(pipe, message) do
          info = {}
          yield info if block_given?
        end
      end

      # Subscribe to a NATS queue.
      #
      # @param type [Symbol] the NATS exchange type, possible
      #   values are: :direct and :fanout.
      # @param pipe [String] the NATS exhange name.
      # @param funnel [String] the NATS queue.
      # @param options [Hash] the options to consume messages with.
      # @yield [info, message] passes message info and content to the
      #   consumer callback/block.
      # @yieldparam info [Hash] contains message information.
      # @yieldparam message [String] message.
      def subscribe(type, pipe, funnel=nil, options={})
        options = { :queue => (type == :direct) ? funnel : nil }
        @subscriptions << @connection.subscribe(pipe, options) do |msg, reply, sub|
          info = { :sub => sub }
          yield info, msg if block_given?
        end
      end

      # Unsubscribe from all NATS queues.
      #
      # @yield [info] passes info to an optional callback/block.
      # @yieldparam info [Hash] contains unsubscribe information.
      def unsubscribe
        @subscriptions.each do |subscription_id|
          info = { :subscription_id => subscription_id }
          @connection.unsubscribe(subscription_id)
          yield info if block_given?
        end
      end

      # Acknowledge the delivery of a message from NATS.
      #
      # @param info [Hash] message info containing its delivery tag.
      # @yield [info] passes acknowledgment info to an optional
      #   callback/block.
      def acknowledge(info)
        # XXX: I think this is only available in NATS Streaming.
      end

      # A proper alias for acknowledge().
      alias_method :ack, :acknowledge

      # NATS queue stats, including message and consumer counts.
      #
      # @param funnel [String] the NATS queue to get stats for.
      # @param options [Hash] the options to get queue stats with.
      # @yield [info] passes queue stats to the callback/block.
      # @yieldparam info [Hash] contains queue stats.
      def stats(funnel, options={})
        # XXX: The Ruby client for NATS doesn't seem to populate these.
        info = {
          :msgs_received  => @connection.msgs_received,
          :msgs_sent      => @connection.msgs_sent,
          :bytes_received => @connection.bytes_received,
          :bytes_sent     => @connection.bytes_sent,
          :pings          => @connection.pings,
        }
        yield info if block_given?
      end

      private

      # Catch NATS errors and call the on_error callback,
      # providing it with the error object as an argument. This method
      # is intended to be applied where necessary, not to be confused
      # with a catch-all.
      #
      # @yield [] callback/block to execute within a rescue block to
      #   catch NATS errors.
      def catch_errors
        begin
          yield
        rescue ::NATS::Error => error
          @on_error.call(error)
        end
      end

      def reset
        @connection.close unless @connection.nil?
        @subscriptions = Set.new
      end

      def start(options={})
        @connection = ::NATS.connect(options) { succeed }
      end
    end
  end
end
