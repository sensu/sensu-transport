module AMQP
  class Session
    def send_heartbeat
      if tcp_connection_established? && !reconnecting?
        send_frame(AMQ::Protocol::HeartbeatFrame)
        if !@handling_skipped_heartbeats && @last_server_heartbeat
          if @last_server_heartbeat < (Time.now - (self.heartbeat_interval * 2))
            logger.error("[amqp] Detected missing amqp heartbeats")
            self.handle_skipped_heartbeats
          end
        end
      end
    end
  end
end
