require_relative './bench_init'

context "Client Connection" do
  host = Connection::Controls::Host::Localhost.example
  port = Connection::Controls::TestServer.port

  context "I/O" do
    test "Reading and writing" do
      iteration = 1
      client = Connection::Client.build host, port

      client.write "#{iteration}\n"
      response = client.read
      client.close

      assert response == "0\n"
    end

    test "Reading a single line" do
      iteration = 2
      client = Connection::Client.build host, port

      client.write "#{iteration}\n"
      response = client.gets
      client.close

      assert response == "1\n"
    end
  end
end
