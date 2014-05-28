module Sensu
  module Transport
    class << self
      # Set the transport logger.
      #
      # @param logger [Object] transport logger.
      def logger=(logger)
        @logger = logger
      end

      # Set the transport error callback.
      #
      # @param callback [Proc] called in the event of a transport
      #   error, an exception object will be passed as a parameter.
      # @return [Proc] the error callback.
      def on_error(&callback)
        @on_error = callback
      end

      # Set the transport before reconnect callback.
      #
      # @param callback [Proc] called before attempting to reconnect
      #   to the transport.
      # @return [Proc] the before reconnect callback.
      def before_reconnect(&callback)
        @before_reconnect = callback
      end

      # Set the transport after reconnect callback.
      #
      # @param callback [Proc] called after reconnecting to the
      #   transport.
      # @return [Proc] the after reconnect callback.
      def after_reconnect(&callback)
        @after_reconnect = callback
      end

      # Connect to a transport.
      #
      # @param transport_name [String] transport name.
      # @param options [Hash] transport options.
      def connect(transport_name, options={})
        require("sensu/transport/#{transport_name}")
        klass = Base.descendants.detect do |klass|
          klass.name.downcase.split("::").last == transport_name
        end
        transport = klass.new
        transport.logger = @logger if @logger
        transport.on_error = @on_error if @on_error
        transport.before_reconnect = @before_reconnect if @before_reconnect
        transport.after_reconnect = @after_reconnect if @after_reconnect
        transport.connect(options)
        transport
      end
    end
  end
end
