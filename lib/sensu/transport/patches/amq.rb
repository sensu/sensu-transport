module AMQ
  module Client
    module Async
      module Adapter
        def send_heartbeat
          if tcp_connection_established? && !reconnecting?
            if !@handling_skipped_hearbeats && @last_server_heartbeat
              send_frame(Protocol::HeartbeatFrame)
              if @last_server_heartbeat < (Time.now - (self.heartbeat_interval * 2))
                logger.error('detected missing amqp heartbeats')
                self.handle_skipped_hearbeats
              end
            end
          end
        end
      end
    end
  end
end
