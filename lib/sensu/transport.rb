module Sensu
  module Transport
    class << self
      # Set the transport logger.
      #
      # @param logger [Object] transport logger.
      def logger=(logger)
        @logger = logger
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
        transport.logger = @logger
        transport.connect(options)
        transport
      end
    end
  end
end
