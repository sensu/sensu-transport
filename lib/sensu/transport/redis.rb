gem "em-redis-unified"

require "em-redis"

require File.join(File.dirname(__FILE__), "base")

module Sensu
  module Transport
    class Redis < Base

      REDIS_KEYSPACE = "transport:"

      def connect(options={})
        reset
        @redis = setup_connection(options)
        @pubsub = setup_connection(options)
      end

      def reconnect
        @redis.reconnect!
        @pubsub.reconnect!
      end

      def connected?
        @redis.connected? && @pubsub.connected?
      end

      def close
        @redis.close
        @pubsub.close
      end

      def publish(type, pipe, message, options={}, &callback)
        case type
        when "fanout"
          pubsub_publish(pipe, message, &callback)
        when "direct"
          list_publish(pipe, message, &callback)
        end
      end

      def subscribe(type, pipe, funnel=nil, options={}, &callback)
        case type
        when "fanout"
          pubsub_subscribe(pipe, &callback)
        when "direct"
          list_subscribe(pipe, &callback)
        end
      end

      def unsubscribe(&callback)
        @pubsub.unsubscribe
        @subscribed = {}
        super
      end

      def stats(funnel, options={}, &callback)
        @redis.llen(funnel) do |messages|
          info = {
            :messages => messages,
            :consumers => 0
          }
          callback.call(info)
        end
      end

      private

      def reset
        @subscribed = {}
      end

      def setup_connection(options)
        connection = EM::Protocols::Redis.connect(options)
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
        connection
      end

      def pubsub_publish(pipe, message, &callback)
        channel = REDIS_KEYSPACE + pipe
        @redis.publish(channel, message) do |subscribers|
          info = {:subscribers => subscribers}
          callback.call(info) if callback
        end
      end

      def pubsub_subscribe(pipe, &callback)
        channel = REDIS_KEYSPACE + pipe
        @pubsub.subscribe(channel) do |type, channel, message|
          case type
          when "subscribe"
            @logger.debug("subscribed to redis channel", :channel => channel) if @logger
            @subscribed[channel] = true
          when "unsubscribe"
            @logger.debug("unsubscribed from redis channel", :channel => channel) if @logger
            @subscribed.delete(channel)
          when "message"
            info = {:channel => channel}
            callback.call(info, message)
          end
        end
      end

      def list_publish(pipe, message, &callback)
        list = REDIS_KEYSPACE + pipe
        @redis.rpush(list, message) do |queued|
          info = {:queued => queued}
          callback.call(info) if callback
        end
      end

      def list_lpop(list, &callback)
        @redis.lpop(list) do |message|
          if @subscribed[list]
            EM::next_tick {list_lpop(list, &callback)}
          end
          callback.call({}, message) unless message.nil?
        end
      end

      def list_subscribe(pipe, &callback)
        list = REDIS_KEYSPACE + pipe
        @subscribed[list] = true
        list_lpop(list, &callback)
      end
    end
  end
end
