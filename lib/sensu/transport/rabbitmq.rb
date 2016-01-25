gem "bunny", "2.2.2"

require "bunny"

require File.join(File.dirname(__FILE__), "base")

module Sensu
  module Transport
    class RabbitMQ < Base
      # RabbitMQ connection setup.
      #
      # @param options [Hash, String]
      def connect(options={})
        reset
        set_connection_options(options)
        connect_with_eligible_options
      end

      # Reconnect to RabbitMQ.
      #
      # @param force [Boolean] the reconnect.
      def reconnect(force=false)
        @before_reconnect.call unless @reconnecting
        @reconnecting = true
        reset
        connect_with_eligible_options do
          @reconnecting = false
          @after_reconnect.call
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
        @connection.close
      end

      # Publish a message to RabbitMQ.
      #
      # @param type [Symbol] the RabbitMQ exchange type, possible
      #   values are: :direct and :fanout.
      # @param pipe [String] the RabbitMQ exchange name.
      # @param message [String] the message to be published to RabbitMQ.
      # @param options [Hash] the options to publish the message with.
      # @yield [info] passes publish info to an optional callback/block.
      # @yieldparam info [Hash] contains publish information.
      def publish(type, pipe, message, options={}, &callback)
        catch_errors do
          @channel.method(type.to_sym).call(pipe, options).publish(message)
          info = {}
          callback.call(info) if callback
        end
      end

      # Subscribe to a RabbitMQ queue.
      #
      # @param type [Symbol] the RabbitMQ exchange type, possible
      #   values are: :direct and :fanout.
      # @param pipe [String] the RabbitMQ exhange name.
      # @param funnel [String] the RabbitMQ queue.
      # @param options [Hash] the options to consume messages with.
      # @yield [info, message] passes message info and content to
      #   the consumer callback/block.
      # @yieldparam info [Hash] contains message information.
      # @yieldparam message [String] message.
      def subscribe(type, pipe, funnel=nil, options={}, &callback)
        catch_errors do
          options[:manual_ack] = options.delete(:ack)
          @funnels[funnel] ||= {
            :queue => @channel.queue(funnel, :auto_delete => true),
            :bindings => [],
            :consumer => nil
          }
          queue = @funnels[funnel][:queue]
          unless @funnels[funnel][:bindings].include?(pipe)
            queue.bind(@channel.method(type.to_sym).call(pipe))
            @funnels[funnel][:bindings] << pipe
          end
          @funnels[funnel][:consumer] ||= queue.subscribe(options) do |info, metadata, message|
            callback.call(info, message)
          end
        end
      end

      # Unsubscribe from all RabbitMQ queues. Cancelling queue
      # consumers will cause the auto-delete queues to be deleted.
      #
      # @yield [info] passes info to an optional callback/block.
      # @yieldparam info [Hash] contains unsubscribe information.
      def unsubscribe(&callback)
        catch_errors do
          if connected?
            @funnels.each do |funnel, info|
              info.delete(:consumer).cancel if info[:consumer]
            end
            @channel.recover
          end
          super
        end
      end

      # Acknowledge the delivery of a message from RabbitMQ.
      #
      # @param info [Hash] message info containing its delivery tag.
      # @yield [info] passes acknowledgment info to an optional
      #   callback/block.
      def acknowledge(info, &callback)
        catch_errors do
          @channel.ack(info.delivery_tag)
          super
        end
      end

      # RabbitMQ queue stats, including message and consumer counts.
      #
      # @param funnel [String] the RabbitMQ queue to get stats for.
      # @param options [Hash] the options to get queue stats with.
      # @yield [info] passes queue stats to the callback/block.
      def stats(funnel, options={}, &callback)
        catch_errors do
          options = options.merge(:auto_delete => true)
          queue = @channel.queue_declare(funnel, options)
          info = {
            :messages => queue.message_count,
            :consumers => queue.consumer_count
          }
          callback.call(info)
        end
      end

      private

      def catch_errors(&block)
        begin
          block.call
        rescue Bunny::Exception => error
          @on_error.call(error)
        end
      end

      def set_connection_options(options)
        @connection_options = [options].flatten
      end

      def reset
        @funnels = {}
        close if @connection
      end

      def next_connection_options
        if @eligible_options.nil? || @eligible_options.empty?
          @eligible_options = @connection_options.shuffle
        end
        @eligible_options.shift
      end

      def setup_connection(options={}, &callback)
        catch_errors do
          additional_options = {
            :automatically_recover => false,
            :recover_from_connection_close => false
          }
          additional_options[:logger] = @logger if @logger
          @connection = Bunny.new(options, additional_options)
          @connection.start
          @channel = @connection.create_channel
          prefetch = 1
          if options.is_a?(Hash)
            prefetch = options.fetch(:prefetch, 1)
          end
          @channel.prefetch(prefetch)
          callback.call if callback
        end
      end

      def connect_with_eligible_options(&callback)
        options = next_connection_options
        setup_connection(options, &callback)
      end
    end
  end
end
