gem "em-redis-unified"

require "em-redis"

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
        setup_connection("pubsub")
      end

      def reconnect
        # no-op for now
      end

      def connected?
        @connections.values.all? do |connection|
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
          when "redis"
            # no-op
          when "pubsub"
            connection.unsubscribe
          else
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

      def reset
        @connections = {}
      end

      def setup_connection(name)
        return @connections[name] if @connections[name]
        connection = EM::Protocols::Redis.connect(@options)
        connection.on_error do |error|
          @on_error.call(error)
        end
        connection.before_reconnect do
          @before_reconnect.call unless @reconnecting
          @reconnecting = true
        end
        connection.after_reconnect do
          @after_reconnect.call if @reconnecting
          @reconnecting = false
        end
        @connections[name] = connection
        connection
      end

      def pubsub_publish(pipe, message, &callback)
        channel = [REDIS_KEYSPACE, "channel", pipe].join(":")
        @connections["redis"].publish(channel, message) do |subscribers|
          info = {:subscribers => subscribers}
          callback.call(info) if callback
        end
      end

      def pubsub_subscribe(pipe, &callback)
        channel = [REDIS_KEYSPACE, "channel", pipe].join(":")
        @connections["pubsub"].subscribe(channel) do |type, channel, message|
          case type
          when "subscribe"
            @logger.debug("subscribed to redis channel", :channel => channel) if @logger
          when "unsubscribe"
            @logger.debug("unsubscribed from redis channel", :channel => channel) if @logger
          when "message"
            info = {:channel => channel}
            callback.call(info, message)
          end
        end
      end

      def list_publish(pipe, message, &callback)
        list = [REDIS_KEYSPACE, "list", pipe].join(":")
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
        list = [REDIS_KEYSPACE, "list", pipe].join(":")
        setup_connection(list)
        list_blpop(list, &callback)
      end
    end
  end
end
