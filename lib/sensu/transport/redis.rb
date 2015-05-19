require "em-redis-unified"

require File.join(File.dirname(__FILE__), "base")

module Sensu
  module Transport
    class Redis < Base

      # The Redis keyspace to use for the transport.
      REDIS_KEYSPACE = "transport"

      def initialize
        @options = {}
        @connections = {}
        super
      end

      # Redis transport connection setup. This method sets `@options`
      # and creates a named Redis connection "redis".
      #
      # @param options [Hash, String]
      def connect(options={})
        @options = options || {}
        redis_connection("redis")
      end

      # Reconnect to the Redis transport. The Redis connections used
      # by the transport have auto-reconnect disabled; if a single
      # connection is unhealthy, all connections are closed, the
      # transport is reset, and new connections are made. If the
      # transport is not already reconnecting to Redis, the
      # `@before_reconnect` transport callback is called.
      #
      # @param force [Boolean] the reconnect.
      def reconnect(force=false)
        @before_reconnect.call unless @reconnecting
        unless @reconnecting && !force
          @reconnecting = true
          close
          reset
          connect
        end
      end

      # Indicates if ALL Redis connections are connected.
      #
      # @return [TrueClass, FalseClass]
      def connected?
        !@connections.empty? && @connections.values.all? do |connection|
          connection.connected?
        end
      end

      # Close ALL Redis connections.
      def close
        @connections.each_value do |connection|
          connection.close
        end
      end

      # Publish a message to the Redis transport. The transport pipe
      # type determines the method of sending messages to consumers
      # using Redis, either using PubSub or a list. The appropriate
      # publish method is call for the pipe type given. The Redis
      # transport ignores publish options.
      #
      # @param type [Symbol] the transport pipe type, possible values
      #   are: :direct and :fanout.
      # @param pipe [String] the transport pipe name.
      # @param message [String] the message to be published to the transport.
      # @param options [Hash] IGNORED by this transport.
      # @yield [info] passes publish info to an optional callback/block.
      # @yieldparam info [Hash] contains publish information, which
      #   may contain an error object.
      def publish(type, pipe, message, options={}, &callback)
        case type.to_sym
        when :fanout
          pubsub_publish(pipe, message, &callback)
        when :direct
          list_publish(pipe, message, &callback)
        end
      end

      # Subscribe to a Redis transport pipe. The transport pipe
      # type determines the method of consuming messages from Redis,
      # either using PubSub or a list. The appropriate subscribe
      # method is call for the pipe type given. The Redis transport
      # ignores subscribe options and the funnel name.
      #
      # @param type [Symbol] the transport pipe type, possible values
      #   are: :direct and :fanout.
      # @param pipe [String] the transport pipe name.
      # @param funnel [String] IGNORED by this transport.
      # @param options [Hash] IGNORED by this transport.
      # @yield [info, message] passes message info and content to
      #   the consumer callback/block.
      # @yieldparam info [Hash] contains message information.
      # @yieldparam message [String] message.
      def subscribe(type, pipe, funnel=nil, options={}, &callback)
        case type.to_sym
        when :fanout
          pubsub_subscribe(pipe, &callback)
        when :direct
          list_subscribe(pipe, &callback)
        end
      end

      # Unsubscribe from all transport pipes. This method iterates
      # through the current named Redis connections, unsubscribing the
      # "pubsub" connection from Redis channels, and closing/deleting
      # BLPOP connections.
      #
      # @yield [info] passes info to an optional callback/block.
      # @yieldparam info [Hash] empty hash.
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

      # Redis transport pipe/funnel stats, such as message and
      # consumer counts. This method is currently unable to determine
      # the consumer count for a Redis list.
      #
      # @param funnel [String] the transport funnel to get stats for.
      # @param options [Hash] IGNORED by this transport.
      def stats(funnel, options={}, &callback)
        redis_connection("redis").llen(funnel) do |messages|
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

      # Monitor current Redis connections, the connection "pool". A
      # timer is used to check on the connections, every `3` seconds.
      # If one or more connections is not connected, a forced
      # `reconnect()` is triggered. If all connections are connected
      # after reconnecting, the transport `@after_reconnect`
      # callback is called. If a connection monitor (timer) already
      # exists, it is canceled.
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

      # Return or setup a named Redis connection. This method creates
      # a Redis connection object using the provided Redis transport
      # options. Redis auto-reconnect is disabled as the connection
      # "pool" is monitored as a whole. The transport `@on_error`
      # callback is called when Redis errors are encountered. This
      # method creates/replaces the connection monitor after setting
      # up the connection and before adding it to the pool.
      #
      # @param name [String] the Redis connection name.
      # @return [Object]
      def redis_connection(name)
        return @connections[name] if @connections[name]
        connection = EM::Protocols::Redis.connect(@options)
        connection.auto_reconnect = false
        connection.reconnect_on_error = false
        connection.on_error do |error|
          @on_error.call(error)
        end
        monitor_connections
        @connections[name] = connection
        connection
      end

      # Create a Redis key within the defined Redis keyspace. This
      # method is used to create keys that are unlikely to collide.
      # The Redis connection database number is included in the Redis
      # key as pubsub is not scoped to the selected database.
      #
      # @param type [String]
      # @param name [String]
      # @return [String]
      def redis_key(type, name)
        db = @options[:db] || 0
        [REDIS_KEYSPACE, db, type, name].join(":")
      end

      # Publish a message to a Redis channel (PubSub). The
      # `redis_key()` method is used to create a Redis channel key,
      # using the transport pipe name. The publish callback info
      # includes the current subscriber count for the Redis channel.
      #
      # http://redis.io/topics/pubsub
      #
      # @param pipe [String] the transport pipe name.
      # @param message [String] the message to be published to the transport.
      # @yield [info] passes publish info to an optional callback/block.
      # @yieldparam info [Hash] contains publish information.
      # @yieldparam subscribers [String] current subscriber count.
      def pubsub_publish(pipe, message, &callback)
        channel = redis_key("channel", pipe)
        redis_connection("redis").publish(channel, message) do |subscribers|
          info = {:subscribers => subscribers}
          callback.call(info) if callback
        end
      end

      # Subscribe to a Redis channel (PubSub). The `redis_key()`
      # method is used to create a Redis channel key, using the
      # transport pipe name. The named Redis connection "pubsub" is
      # used for the Redis SUBSCRIBE command set, as the Redis context
      # is limited and enforced for the connection. The subscribe
      # callback is called whenever a message is published to the
      # Redis channel. Channel messages with the type "subscribe" and
      # "unsubscribe" are ignored, only messages with type "message"
      # are passsed to the provided consumer/method callback/block.
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
        redis_connection("pubsub").subscribe(channel) do |type, channel, message|
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

      # Push (publish) a message onto a Redis list. The `redis_key()`
      # method is used to create a Redis list key, using the transport
      # pipe name. The publish callback info includes the current list
      # size (queued).
      #
      # @param pipe [String] the transport pipe name.
      # @param message [String] the message to be published to the transport.
      # @yield [info] passes publish info to an optional callback/block.
      # @yieldparam info [Hash] contains publish information.
      # @yieldparam queued [String] current list size.
      def list_publish(pipe, message, &callback)
        list = redis_key("list", pipe)
        redis_connection("redis").rpush(list, message) do |queued|
          info = {:queued => queued}
          callback.call(info) if callback
        end
      end

      # Shift a message off of a Redis list and schedule another shift
      # on the next tick of the event loop (reactor). Redis BLPOP is a
      # connection blocking Redis command, this method creates a named
      # Redis connection for each list. Multiple Redis connections for
      # BLPOP commands is far more efficient than timer or next tick
      # polling with LPOP.
      #
      # @param list [String]
      # @yield [info, message] passes message info and content to
      #   the consumer/method callback/block.
      # @yieldparam info [Hash] an empty hash.
      # @yieldparam message [String] message content.
      def list_blpop(list, &callback)
        redis_connection(list).blpop(list, 0) do |_, message|
          EM::next_tick {list_blpop(list, &callback)}
          callback.call({}, message)
        end
      end

      # Subscribe to a Redis list, shifting message off as they become
      # available. The `redis_key()` method is used to create a Redis
      # list key, using the transport pipe name. The `list_blpop()`
      # method is used to do the actual work.
      #
      # @param pipe [String] the transport pipe name.
      # @yield [info, message] passes message info and content to
      #   the consumer/method callback/block.
      # @yieldparam info [Hash] an empty hash.
      # @yieldparam message [String] message content.
      def list_subscribe(pipe, &callback)
        list = redis_key("list", pipe)
        list_blpop(list, &callback)
      end
    end
  end
end
