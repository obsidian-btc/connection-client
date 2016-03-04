class Connection
  class Client
    module ReconnectPolicy
      extend self

      def get(policy_name)
        policy_class = self.policy_class policy_name
        policy_class.build
      end

      def logger
        ::Telemetry::Logger.get self
      end

      def policy_class(policy_name=nil)
        policy_name ||= Defaults::Name.get

        policy_class = policies[policy_name]

        unless policy_class
          error_msg = "Refresh policy \"#{policy_name}\" is unknown. It must be one of: never or :closed."
          logger.error error_msg
          raise Error, error_msg
        end

        policy_class
      end

      def policies
        @policies ||= {
          :never => Never,
          :closed => Closed
        }
      end

      Error = Class.new StandardError
    end
  end
end
