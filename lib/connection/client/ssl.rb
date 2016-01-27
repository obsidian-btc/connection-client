class Connection
  class Client
    class SSL < Client
      attr_writer :ssl_context

      def establish_connection
        socket = TCPSocket.new host, port
        ssl_socket = enable_ssl socket
        ssl_socket
      end

      def enable_ssl(raw_socket)
        logger.opt_trace "Enabling SSL (Host: #{host.inspect}, Port: #{port}, Fileno: #{Fileno.get raw_socket})"

        socket = OpenSSL::SSL::SSLSocket.new raw_socket, ssl_context

        loop do
          result = socket.connect_nonblock :exception => false
          if result == :wait_readable
            logger.opt_trace "Not ready for SSL handshake; deferring (Host: #{host.inspect}, Port: #{port}, Fileno: #{Fileno.get socket})"

            scheduler.wait_readable raw_socket

            logger.opt_debug "Ready for SSL handshake (Host: #{host.inspect}, Port: #{port}, Fileno: #{Fileno.get socket})"
            next
          end
          break
        end

        logger.opt_debug "SSL enabled (Host: #{host.inspect}, Port: #{port}, Fileno: #{Fileno.get socket})"

        socket
      end

      def ssl_context
        @ssl_context ||=
          begin
            context = OpenSSL::SSL::SSLContext.new
            context.verify_mode = OpenSSL::SSL::VERIFY_PEER
            context
          end
      end
    end
  end
end
