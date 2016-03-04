class Connection
  class Client
    module ReconnectPolicy
      class Closed
        include ReconnectPolicy

        dependency :logger, ::Telemetry::Logger

        def self.build
          instance = new
          ::Telemetry::Logger.configure instance
          instance
        end

        def control_connection(connection)
          logger.opt_trace "Controlling connection (Fileno: #{connection.fileno}, Closed: #{connection.closed?})"

          if connection.closed?
            connection.reconnect
            logger.opt_debug "Reconnected (Fileno: #{connection.fileno})"
          else
            logger.opt_debug "Nothing to do (Fileno: #{connection.fileno})"
          end
        end
      end
    end
  end
end
