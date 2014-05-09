module Sensu
  module Transport
    def self.connect(transport, options={})
      require("sensu/transport/#{transport}")
      klass = Base.descendants.detect do |klass|
        klass.name.downcase.split("::").last == transport
      end
      object = klass.connect(options)
      object
    end
  end
end
