require_relative './bench_init'

context "Client Connection" do
  host = Connection::Controls::Host::Localhost.example
  port = Connection::Controls::TestServer.ssl_port
  ssl_context = Connection::Controls::SSL::Context::Client.example

  context "SSL" do
    test "Reading and writing" do
      iteration = 1
      client = Connection::Client.build host, port, ssl: ssl_context

      client.write "#{iteration}\n"
      response = client.read

      assert response == "0\n"
    end
  end
end
