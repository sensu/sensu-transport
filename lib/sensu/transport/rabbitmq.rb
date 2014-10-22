gem "amqp", "1.3.0"

require "amqp"

require File.join(File.dirname(__FILE__), "base")

module Sensu
  module Transport
    class RabbitMQ < Base
      def initialize
        super
        @queues = {}
      end

      def connect(options={})
        set_connection_options(options)
        create_connection_timeout
        connect_with_eligible_options
      end

      def reconnect
        unless @connection.reconnecting?
          @connection_timeout.cancel
          @before_reconnect.call
          timer = EM::PeriodicTimer.new(3) do
            begin
              @connection.reconnect_to(next_connection_options)
            rescue EventMachine::ConnectionError
            end
          end
          @connection.on_recovery do
            timer.cancel
          end
        end
      end

      def connected?
        @connection.connected?
      end

      def close
        callback = Proc.new { @connection.close }
        connected? ? callback.call : EM.next_tick(callback)
      end

      def publish(exchange_type, exchange_name, message, options={}, &callback)
        begin
          @channel.method(exchange_type.to_sym).call(exchange_name, options).publish(message) do
            info = {}
            callback.call(info) if callback
          end
        rescue => error
          info = {:error => error}
          callback.call(info) if callback
        end
      end

      def subscribe(exchange_type, exchange_name, queue_name="", options={}, &callback)
        previously_declared = @queues.has_key?(queue_name)
        @queues[queue_name] ||= @channel.queue!(queue_name, :auto_delete => true)
        queue = @queues[queue_name]
        queue.bind(@channel.method(exchange_type.to_sym).call(exchange_name))
        unless previously_declared
          queue.subscribe(options, &callback)
        end
      end

      def unsubscribe(&callback)
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
        super
      end

      def acknowledge(info, &callback)
        info.ack
        callback.call(info) if callback
      end

      def stats(queue_name, options={}, &callback)
        options = options.merge(:auto_delete => true)
        @channel.queue(queue_name, options).status do |messages, consumers|
          info = {
            :messages => messages,
            :consumers => consumers
          }
          callback.call(info)
        end
      end

      private

      def set_connection_options(options)
        @connection_options = Array(options)
      end

      def create_connection_timeout
        @connection_timeout = EM::Timer.new(20) do
          error = Error.new("timed out while attempting to connect to rabbitmq")
          @on_error.call(error)
        end
      end

      def next_connection_options
        if @eligible_options.nil? || @eligible_options.empty?
          @eligible_options = @connection_options.shuffle
        end
        @eligible_options.shift
      end

      def connect_with_eligible_options
        options = next_connection_options
        reconnect_callback = Proc.new { reconnect }
        @connection = AMQP.connect(options, {
          :on_tcp_connection_failure => reconnect_callback,
          :on_possible_authentication_failure => reconnect_callback
        })
        @connection.logger = @logger
        @connection.on_open do
          @connection_timeout.cancel
        end
        @connection.on_tcp_connection_loss(&reconnect_callback)
        @connection.on_skipped_heartbeats(&reconnect_callback)
        setup_channel(options)
      end

      def setup_channel(options={})
        @channel = AMQP::Channel.new(@connection)
        @channel.auto_recovery = true
        @channel.on_error do |channel, channel_close|
          error = Error.new("rabbitmq channel closed")
          @on_error.call(error)
        end
        prefetch = 1
        if options.is_a?(Hash)
          prefetch = options.fetch(:prefetch, 1)
        end
        @channel.prefetch(prefetch)
        @channel.on_recovery do
          @after_reconnect.call
        end
      end
    end
  end
end
