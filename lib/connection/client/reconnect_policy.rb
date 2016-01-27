class Connection
  class Client
    module ReconnectPolicy
      def self.get(policy_name)
        policy_class = self.policy_class policy_name
        policy_class.build
      end

      def self.logger
        Telemetry::Logger.get self
      end

      def self.policy_class(policy_name=nil)
        policy_name ||= Defaults::Name.get

        policy_class = policies[policy_name]

        unless policy_class
          error_msg = "Refresh policy \"#{policy_name}\" is unknown. It must be one of: never or when_closed."
          logger.error error_msg
          raise Error, error_msg
        end

        policy_class
      end

      def self.policies
        @policies ||= {
          :never => Never,
          :when_closed => WhenClosed
        }
      end

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

      class WhenClosed
        include ReconnectPolicy

        dependency :logger, Telemetry::Logger

        def self.build
          instance = new
          Telemetry::Logger.configure instance
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

      Error = Class.new StandardError

      module Defaults
        module Name
          def self.get
            :never
          end
        end
      end
    end
  end
end
