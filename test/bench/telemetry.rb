require_relative './bench_init'

context "Capturing Telemetry" do
  host = Connection::Controls::Host::Localhost.example
  port = Connection::Controls::TestServer.port

  test do
    client = Connection::Client.build host, port
    sink = Connection::Client.register_telemetry_sink client

    client.write "1\n"
    client.read
    client.close

    assert sink do
      written?("1\n") && read?("0\n")
    end
  end

  test "Gets" do
    client = Connection::Client.build host, port
    sink = Connection::Client.register_telemetry_sink client

    client.write "1\n"
    client.gets
    client.close

    assert sink do
      read?("0\n")
    end
  end

  test "Readline" do
    client = Connection::Client.build host, port
    sink = Connection::Client.register_telemetry_sink client

    client.write "1\n"
    client.readline
    client.close

    assert sink do
      read?("0\n")
    end
  end
end
