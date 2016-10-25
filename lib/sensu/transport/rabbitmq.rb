gem "amqp", "1.6.0"

require "amqp"

require File.join(File.dirname(__FILE__), "base")
require File.join(File.dirname(__FILE__), "patches", "amqp")

module Sensu
  module Transport
    class RabbitMQ < Base
      # RabbitMQ connection setup. The deferred status is set to
      # `:succeeded` (via `succeed()`) once the connection has been
      # established.
      #
      # @param options [Hash, String]
      def connect(options={})
        reset
        set_connection_options(options)
        create_connection_timeout
        connect_with_eligible_options
      end

      # Reconnect to RabbitMQ.
      #
      # @param force [Boolean] the reconnect.
      def reconnect(force=false)
        unless @reconnecting
          @reconnecting = true
          @logger.debug("Reconnecting...")
          @before_reconnect.call
          reset
          periodically_reconnect
        end
      end

      # Indicates if connected to RabbitMQ.
      #
      # @return [TrueClass, FalseClass]
      def connected?
        @connection.connected?
      end

      # Close the RabbitMQ connection.
      def close
        callback = Proc.new { @connection.close }
        connected? ? callback.call : EM.next_tick(callback)
      end

      # Publish a message to RabbitMQ.
      #
      # @param type [Symbol] the RabbitMQ exchange type, possible
      #   values are: :direct and :fanout.
      # @param pipe [String] the RabbitMQ exchange name.
      # @param message [String] the message to be published to
      #   RabbitMQ.
      # @param options [Hash] the options to publish the message with.
      # @yield [info] passes publish info to an optional
      #   callback/block.
      # @yieldparam info [Hash] contains publish information.
      def publish(type, pipe, message, options={})
        catch_errors do
          @channel.method(type.to_sym).call(pipe, options).publish(message) do
            info = {}
            yield(info) if block_given?
          end
        end
      end

      # Subscribe to a RabbitMQ queue.
      #
      # @param type [Symbol] the RabbitMQ exchange type, possible
      #   values are: :direct and :fanout.
      # @param pipe [String] the RabbitMQ exhange name.
      # @param funnel [String] the RabbitMQ queue.
      # @param options [Hash] the options to consume messages with.
      # @yield [info, message] passes message info and content to the
      #   consumer callback/block.
      # @yieldparam info [Hash] contains message information.
      # @yieldparam message [String] message.
      def subscribe(type, pipe, funnel="", options={}, &callback)
        catch_errors do
          previously_declared = @queues.has_key?(funnel)
          @queues[funnel] ||= @channel.queue!(funnel, :auto_delete => true)
          queue = @queues[funnel]
          queue.bind(@channel.method(type.to_sym).call(pipe))
          unless previously_declared
            queue.subscribe(options, &callback)
          end
        end
      end

      # Unsubscribe from all RabbitMQ queues.
      #
      # @yield [info] passes info to an optional callback/block.
      # @yieldparam info [Hash] contains unsubscribe information.
      def unsubscribe
        catch_errors do
          @queues.values.each do |queue|
            if connected?
              queue.unsubscribe
            else
              queue.before_recovery do
                queue.unsubscribe
              end
            end
          end
          @queues = {}
          @channel.recover if connected?
        end
        super
      end

      # Acknowledge the delivery of a message from RabbitMQ.
      #
      # @param info [Hash] message info containing its delivery tag.
      # @yield [info] passes acknowledgment info to an optional
      #   callback/block.
      def acknowledge(info)
        catch_errors do
          info.ack
        end
        super
      end

      # A proper alias for acknowledge().
      alias_method :ack, :acknowledge

      # RabbitMQ queue stats, including message and consumer counts.
      #
      # @param funnel [String] the RabbitMQ queue to get stats for.
      # @param options [Hash] the options to get queue stats with.
      # @yield [info] passes queue stats to the callback/block.
      # @yieldparam info [Hash] contains queue stats.
      def stats(funnel, options={})
        catch_errors do
          options = options.merge(:auto_delete => true)
          @channel.queue(funnel, options).status do |messages, consumers|
            info = {
              :messages => messages,
              :consumers => consumers
            }
            yield(info)
          end
        end
      end

      private

      # Catch RabbitMQ errors and call the on_error callback,
      # providing it with the error object as an argument. This method
      # is intended to be applied where necessary, not to be confused
      # with a catch-all.
      #
      # @yield [] callback/block to execute within a rescue block to
      #   catch RabbitMQ errors.
      def catch_errors
        begin
          yield
        rescue AMQP::Error => error
          @on_error.call(error)
        end
      end

      def reset
        @queues = {}
        @connection_timeout.cancel if @connection_timeout
        @connection.close_connection if @connection
      end

      def set_connection_options(options)
        @connection_options = [options].flatten
      end

      def create_connection_timeout
        @connection_timeout = EM::Timer.new(20) do
          reconnect
        end
      end

      def next_connection_options
        if @eligible_options.nil? || @eligible_options.empty?
          @eligible_options = @connection_options.shuffle
        end
        @eligible_options.shift
      end

      def setup_connection(options={})
        reconnect_callback = Proc.new { reconnect }
        on_possible_auth_failure = Proc.new {
          @logger.warn("transport connection error", :reason => "Possible authentication failure. Wrong credentials?")
          reconnect
        }
        user = options[:user] || "(none)"
        @logger.debug("Attempting to connect with configured user #{user}")
        @connection = AMQP.connect(options, {
          :on_tcp_connection_failure => reconnect_callback,
          :on_possible_authentication_failure => on_possible_auth_failure
        })
        @connection.logger = @logger
        @connection.on_open do
          @logger.debug("connection open")
          @connection_timeout.cancel
          succeed
          yield if block_given?
        end
        @connection.on_tcp_connection_loss do
          @logger.warn("transport connection error", :reason => "TCP connection lost")
          reconnect
        end
        @connection.on_skipped_heartbeats do
          @logger.warn("transport connection error", :reason => "Skipped heartbeats")
          reconnect
        end
        @connection.on_closed do
          @logger.debug("connection closed")
        end
      end

      def setup_channel(options={})
        @channel = AMQP::Channel.new(@connection)
        @channel.auto_recovery = true
        @channel.on_error do |channel, channel_close|
          error = Error.new("rabbitmq channel error")
          @on_error.call(error)
        end
        prefetch = 1
        if options.is_a?(Hash)
          prefetch = options.fetch(:prefetch, 1)
        end
        @channel.prefetch(prefetch)
      end

      def connect_with_eligible_options(&callback)
        options = next_connection_options
        setup_connection(options, &callback)
        setup_channel(options)
      end

      def periodically_reconnect(delay=2)
        capped_delay = (delay >= 20 ? 20 : delay)
        EM::Timer.new(capped_delay) do
          unless connected?
            reset
            periodically_reconnect(capped_delay += 2)
            begin
              connect_with_eligible_options do
                @reconnecting = false
                @after_reconnect.call
              end
            rescue EventMachine::ConnectionError
            rescue Java::JavaLang::RuntimeException
            rescue Java::JavaNioChannels::UnresolvedAddressException
            end
          end
        end
      end
    end
  end
end
