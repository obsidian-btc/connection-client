class Connection
  class Client
    class Substitute < Client
      def self.build
        reconnect_policy = ReconnectPolicy.get :never

        instance = new '<substitute>', 0, reconnect_policy
        Telemetry::Logger.configure instance
        instance
      end

      def build_connection
        Connection::Substitute.build
      end

      def eof
        socket.eof
      end

      def expect_read(data)
        socket.expect_read data
      end

      def expect_write(data)
        socket.expect_write data
      end
    end
  end
end
