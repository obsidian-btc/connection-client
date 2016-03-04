class Connection
  class Client
    attr_reader :host
    attr_reader :port
    attr_reader :reconnect_policy
    attr_reader :scheduler
    attr_writer :socket

    dependency :logger, Telemetry::Logger
    dependency :scheduler, Scheduler
    dependency :telemetry, Telemetry

    def initialize(host, port, reconnect_policy)
      @host = host
      @port = port
      @reconnect_policy = reconnect_policy
    end

    def self.build(host, port, reconnect: nil, scheduler: nil, ssl: nil)
      reconnect ||= :never
      reconnect_policy = ReconnectPolicy.get reconnect

      scheduler ||= Scheduler::Blocking.build

      if ssl
        instance = SSL.new host, port, reconnect_policy
        instance.ssl_context = ssl if ssl.is_a? OpenSSL::SSL::SSLContext
      else
        instance = NonSSL.new host, port, reconnect_policy
      end

      if scheduler
        instance.scheduler = scheduler
      else
        Scheduler.configure instance
      end

      ::Telemetry.configure instance
      ::Telemetry::Logger.configure instance
      instance
    end

    def build_connection
      logger.opt_trace "Establishing connection (Host: #{host.inspect}, Port: #{port})"

      socket = establish_connection

      logger.opt_debug "Established connection (Host: #{host.inspect}, Port: #{port}, Fileno: #{Fileno.get socket})"

      Connection.build socket, scheduler
    end

    def close
      logger.opt_trace "Closing socket (Host: #{host.inspect}, Port: #{port}, Fileno: #{fileno})"

      socket.close

      logger.opt_debug "Closed socket (Host: #{host.inspect}, Port: #{port})"
    end

    def closed?
      socket.closed?
    end

    def connected(&block)
      if socket
        reconnect_policy.control_connection self
      end

      block.(socket)
    end

    def gets(*arguments)
      connected do
        data = socket.gets *arguments
        telemetry.record :read, Telemetry::Read.new(data) if data
        data
      end
    end

    def establish_connection
      fail
    end

    def fileno
      socket.fileno
    end

    def io
      socket.io
    end

    def read(*arguments)
      connected do
        data = socket.read *arguments
        telemetry.record :read, Telemetry::Read.new(data) if data
        data
      end
    end

    def readline(*arguments)
      connected do
        data = socket.readline *arguments
        telemetry.record :read, Telemetry::Read.new(data) if data
        data
      end
    end

    def reconnect
      self.socket = nil
    end

    def socket
      @socket ||= build_connection
    end

    def write(data)
      connected do
        bytes_written = socket.write data
        telemetry.record :written, Telemetry::Written.new(data)
        bytes_written
      end
    end

    def self.configure(receiver, *arguments)
      instance = build *arguments
      receiver.connection = instance
    end

    def self.register_telemetry_sink(connection)
      sink = Telemetry.sink
      connection.telemetry.register sink
      sink
    end

    module Telemetry
      class Sink
        include ::Telemetry::Sink

        record :written
        record :read

        def read?(bytes=nil)
          recorded_read? do |record|
            if bytes.nil?
              true
            else
              record.data.bytes == bytes
            end
          end
        end

        def written?(bytes=nil)
          recorded_written? do |record|
            if bytes.nil?
              true
            else
              record.data.bytes == bytes
            end
          end
        end
      end

      IO = Struct.new :bytes
      Read = Class.new IO
      Written = Class.new IO

      def self.sink
        Sink.new
      end
    end

    module Assertions
      def reconnects_after_close?
        close

        reconnected = connected do
          !socket.closed?
        end

        close

        reconnected
      end

      def scheduler_configured?(expected_scheduler)
        socket.scheduler == expected_scheduler
      end
    end
  end
end
