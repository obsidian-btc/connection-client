class Connection
  class Client
    module Controls
      class TestServer
        attr_reader :poll_period
        attr_reader :server_sockets

        dependency :logger, Telemetry::Logger

        def initialize(server_sockets, poll_period)
          @poll_period = poll_period
          @server_sockets = server_sockets
        end

        def self.build
          logger.opt_trace "Establishing server socket (Unencrypted Port: #{port}, SSL Port: #{ssl_port})"

          server_socket = TCPServer.new '0.0.0.0', port

          ssl_context = SSL::Context::Server.example
          ssl_server_raw_socket = TCPServer.new '0.0.0.0', ssl_port
          ssl_server_socket = OpenSSL::SSL::SSLServer.new ssl_server_raw_socket, ssl_context

          logger.opt_debug "Server sockets established (Unencrypted Port: #{port}, SSL Port: #{ssl_port})"

          instance = new [server_socket, ssl_server_socket], poll_period
          Telemetry::Logger.configure instance
          instance
        end

        def self.call
          instance = build
          instance.()
        end

        def call
          loop do
            logger.opt_trace 'Accepting a connection'
            reads, * = ::IO.select raw_sockets, [], [], poll_period

            if reads.nil?
              logger.opt_debug 'No client has connected'
              next
            end

            logger.opt_debug "Client has connected (Count: #{reads.size})"

            reads.each do |raw_server_socket|
              client = accept_socket raw_server_socket
              next unless client

              handle_client client

              logger.opt_trace 'Closing connection'
              client.close
              logger.opt_debug 'Connection closed'
            end
          end
        end

        def handle_client(client)
          loop do
            logger.opt_trace 'Reading message from client'
            line = client.readline
            iteration = line.to_i.abs
            logger.opt_debug "Message read from client (Line: #{line.inspect}, Iteration: #{iteration})"

            iteration -= 1

            logger.opt_trace "Writing reply to client (Iteration: #{iteration})"
            client.puts iteration.to_s
            logger.opt_debug "Wrote reply to client (Iteration: #{iteration})"

            break if iteration.zero?
          end

        rescue EOFError
          logger.warn 'EOFError'

        rescue Errno::EPIPE, Errno::ECONNRESET, Errno::EPROTOTYPE
          logger.opt_debug 'Client has closed the connection'
        end

        def accept_socket(raw_socket)
          server_sockets.each do |server_socket|
            if self.raw_socket(server_socket) == raw_socket
              logger.opt_trace "Accepting client connection (Server Socket: #{server_socket.class.name.inspect})"
              client = server_socket.accept
              logger.opt_debug "Client connection accepted (Server Socket: #{server_socket.class.name.inspect}, Client Socket: #{client.class.name.inspect})"
              return client
            end
          end

          nil

        rescue OpenSSL::SSL::SSLError
          logger.warn 'OpenSSL::SSL::SSLError'
          nil
        end

        def raw_socket(socket)
          if socket.respond_to? :to_io
            socket.to_io
          else
            socket
          end
        end

        def raw_sockets
          server_sockets.map do |server_socket|
            raw_socket server_socket
          end
        end

        def self.verify_running
          socket = TCPSocket.new '127.0.0.1', port
          socket.close

        rescue Errno::ECONNREFUSED
          run_rb = File.expand_path 'test_server/run.rb', __dir__
          logger.error "You must run the test server via `ruby #{run_rb}`"
          exit 1
        end

        def self.logger
          Telemetry::Logger.get self
        end

        def self.poll_period
          2
        end

        def self.port
          Port.example + 1
        end

        def self.ssl_port
          port + 1
        end
      end
    end
  end
end
