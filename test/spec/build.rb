require_relative './spec_init'

context 'Client Connection' do
  host = Connection::Controls::Host::Localhost.example
  port = Connection::Controls::TestServer.port

  context 'Building' do
    context 'Reconnect policy' do
      test 'Default policy is Never' do
        client = Connection::Client.build host, port

        client.close

        assert client.closed?
      end

      test 'Setting policy to WhenClosed' do
        client = Connection::Client.build host, port, :reconnect => :when_closed

        assert client do
          reconnects_after_close?
        end
      end
    end

    test 'Specifying a scheduler' do
      scheduler = Object.new

      client = Connection::Client.build host, port, :scheduler => scheduler

      assert client do
        scheduler_configured? scheduler
      end
    end
  end
end
