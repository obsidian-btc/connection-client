class Connection
  class Client
    module ReconnectPolicy
      class Never
        include ReconnectPolicy

        dependency :logger, Telemetry::Logger

        def self.build
          instance = new
          Telemetry::Logger.configure instance
          instance
        end

        def control_connection(connection)
          logger.opt_debug "NOOP (Fileno: #{connection.fileno})"
        end
      end
    end
  end
end
