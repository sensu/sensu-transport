module Sensu
  module Transport
    def self.load(transport)
      require("sensu/transport/#{transport}")
      klass = Base.descendants.detect do |klass|
        klass.name.downcase.split("::").last == transport
      end
      klass.new
    end
  end
end
