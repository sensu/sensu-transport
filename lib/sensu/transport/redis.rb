require "em-redis-unified"

require File.join(File.dirname(__FILE__), "base")

module Sensu
  module Transport
    class Redis < Base

      REDIS_KEYSPACE = "transport"

      def initialize
        @options = {}
        @connections = {}
        super
      end

      def connect(options={})
        @options = options || {}
        setup_connection("redis")
        monitor_connections
      end

      def reconnect(force=false)
        @before_reconnect.call unless @reconnecting
        unless @reconnecting && !force
          @reconnecting = true
          close
          reset
          connect
        end
      end

      def connected?
        !@connections.empty? && @connections.values.all? do |connection|
          connection.connected?
        end
      end

      def close
        @connections.each_value do |connection|
          connection.close
        end
      end

      def publish(type, pipe, message, options={}, &callback)
        case type.to_sym
        when :fanout
          pubsub_publish(pipe, message, &callback)
        when :direct
          list_publish(pipe, message, &callback)
        end
      end

      def subscribe(type, pipe, funnel=nil, options={}, &callback)
        case type.to_sym
        when :fanout
          pubsub_subscribe(pipe, &callback)
        when :direct
          list_subscribe(pipe, &callback)
        end
      end

      def unsubscribe(&callback)
        @connections.each do |name, connection|
          case name
          when "pubsub"
            connection.unsubscribe
          when /^#{REDIS_KEYSPACE}/
            connection.close
            @connections.delete(name)
          end
        end
        super
      end

      def stats(funnel, options={}, &callback)
        @connections["redis"].llen(funnel) do |messages|
          info = {
            :messages => messages,
            :consumers => 0
          }
          callback.call(info)
        end
      end

      private

      # Reset instance variables, called when reconnecting.
      def reset
        @connections = {}
      end

      # Setup a named Redis connection. This method creates a Redis
      # connection object using the provided Redis transport options.
      # Redis auto-reconnect is disabled as the connection "pool" is
      # monitored as a whole. The transport `@on_error` callback is
      # called when Redis errors are encountered.
      #
      # @param name [String]
      # @return [Object]
      def setup_connection(name)
        connection = EM::Protocols::Redis.connect(@options)
        connection.auto_reconnect = false
        connection.reconnect_on_error = false
        connection.on_error do |error|
          @on_error.call(error)
        end
        @connections[name] = connection
        connection
      end

      # Monitor current Redis connections, the connection "pool". A
      # timer is used to check on the connections, every `3` seconds.
      # If one or more connections is not connected, a forced
      # `reconnect()` is triggered. If all connections are connected
      # after reconnecting, the transport `@after_reconnect`
      # callbacked is called.
      def monitor_connections
        @connection_monitor.cancel if @connection_monitor
        @connection_monitor = EM::PeriodicTimer.new(3) do
          if !connected?
            reconnect(true)
          elsif @reconnecting
            @after_reconnect.call
            @reconnecting = false
          end
        end
      end

      # Create a Redis key within the defined Redis keyspace. This
      # method is used to create keys that are unlikely to collide.
      #
      # @param type [String]
      # @param name [String]
      # @return [String]
      def redis_key(type, name)
        [REDIS_KEYSPACE, type, name].join(":")
      end

      # Publish a message to a Redis channel (PubSub). The
      # `redis_key()` method is used to create a Redis channel key,
      # using the transport pipe name. The publish callback info
      # includes the current subscriber count for the Redis channel.
      #
      # http://redis.io/topics/pubsub
      #
      # @param pipe [String]
      # @param message [String]
      # @yield [info] passes publish info to an optional callback/block.
      # @yieldparam info [Hash] contains publish information.
      # @yieldparam subscribers [String] current subscriber count.
      def pubsub_publish(pipe, message, &callback)
        channel = redis_key("channel", pipe)
        @connections["redis"].publish(channel, message) do |subscribers|
          info = {:subscribers => subscribers}
          callback.call(info) if callback
        end
      end

      # Subscribe to a Redis channel (PubSub). The subscribe callback
      # is called whenever a message is published to the Redis
      # channel. Channel messages with the type "subscribe" and
      # "unsubscribe" are ignored, only messages with type "message"
      # are passsed to the provided consumer/method callback/block.
      # The named Redis connection "pubsub" is used for the SUBSCRIBE
      # command set, as the Redis context is limited and enforced for
      # the connection.
      #
      # http://redis.io/topics/pubsub
      #
      # @param channel [String] the Redis channel name.
      # @yield [info, message] passes message info and content to
      #   the consumer/method callback/block.
      # @yieldparam info [Hash] contains the channel name.
      # @yieldparam message [String] message content.
      def channel_subscribe(channel, &callback)
        @connections["pubsub"].subscribe(channel) do |type, channel, message|
          case type
          when "subscribe"
            @logger.debug("subscribed to redis channel: #{channel}") if @logger
          when "unsubscribe"
            @logger.debug("unsubscribed from redis channel: #{channel}") if @logger
          when "message"
            info = {:channel => channel}
            callback.call(info, message)
          end
        end
      end

      # Subscribe to a Redis channel (PubSub). The `redis_key()`
      # method is used to create a Redis channel key, using the
      # transport pipe name. A named Redis connection is created for
      # Redis PubSub commands, "pubsub", if it hasn't already been
      # created. The `channel_subscribe()` method is used for the
      # actual subscribing.
      #
      # http://redis.io/topics/pubsub
      #
      # @param pipe [String] the transport pipe name.
      # @yield [info, message] passes message info and content to
      #   the consumer/method callback/block.
      # @yieldparam info [Hash] contains the channel name.
      # @yieldparam message [String] message content.
      def pubsub_subscribe(pipe, &callback)
        channel = redis_key("channel", pipe)
        setup_connection("pubsub") unless @connections["pubsub"]
        channel_subscribe(channel, &callback)
      end

      # Push (publish) a message onto a Redis list.
      def list_publish(pipe, message, &callback)
        list = redis_key("list", pipe)
        @connections["redis"].rpush(list, message) do |queued|
          info = {:queued => queued}
          callback.call(info) if callback
        end
      end

      def list_blpop(list, &callback)
        @connections[list].blpop(list, 0) do |_, message|
          EM::next_tick {list_blpop(list, &callback)}
          callback.call({}, message)
        end
      end

      def list_subscribe(pipe, &callback)
        list = redis_key("list", pipe)
        setup_connection(list)
        list_blpop(list, &callback)
      end
    end
  end
end
