require_relative './bench_init'

context "Changing the client connection scheduler" do
  host = Connection::Controls::Host::Localhost.example
  port = Connection::Controls::TestServer.port

  client_connection = Connection::Client.build host, port
  client_connection.connect

  original_scheduler = client_connection.scheduler
  scheduler = Connection::Scheduler::Substitute.build

  client_connection.change_connection_scheduler scheduler

  test "Scheduler is changed on the underlying connection" do
    assert client_connection.connection.scheduler == scheduler
    refute client_connection.connection.scheduler == original_scheduler
  end

  client_connection.close
end
