gem "amqp", "1.5.0"

require "amqp"

require File.join(File.dirname(__FILE__), "base")

module Sensu
  module Transport
    class RabbitMQ < Base
      def connect(options={})
        reset
        set_connection_options(options)
        create_connection_timeout
        connect_with_eligible_options
      end

      def reconnect(force=false)
        unless @reconnecting
          @reconnecting = true
          @before_reconnect.call
          reset
          periodically_reconnect
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

      def reconnect_callback
        Proc.new { reconnect }
      end

      def setup_connection(options={}, &callback)
        @connection = AMQP.connect(options, {
          :on_tcp_connection_failure => reconnect_callback,
          :on_possible_authentication_failure => reconnect_callback
        })
        @connection.logger = @logger
        @connection.on_open do
          @connection_timeout.cancel
          callback.call if callback
        end
        @connection.on_tcp_connection_loss(&reconnect_callback)
        @connection.on_skipped_heartbeats(&reconnect_callback)
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
      end

      def connect_with_eligible_options(&callback)
        options = next_connection_options
        setup_connection(options, &callback)
        setup_channel(options)
      end

      def periodically_reconnect
        timer = EM::PeriodicTimer.new(5) do
          unless connected?
            begin
              connect_with_eligible_options do
                @reconnecting = false
                @after_reconnect.call
              end
            rescue EventMachine::ConnectionError
            rescue Java::JavaLang::RuntimeException
            end
          else
            timer.cancel
          end
        end
      end
    end
  end
end
