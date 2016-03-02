require_relative './spec_init'

context "Client Connection" do
  context "Never reconnect policy" do
    policy = Connection::Client::ReconnectPolicy::Never.new

    test "Does not re-establish a closed connection" do
      connection = Connection::Client::Substitute.build

      connection.close

      policy.control_connection connection

      assert connection.closed?
    end

    test "Does not close an open connection" do
      connection = Connection::Client::Substitute.build

      policy.control_connection connection

      assert !connection.closed?
    end
  end

  context "When Closed reconnect policy" do
    policy = Connection::Client::ReconnectPolicy::Closed.new

    test "Re-establishes an open connection" do
      connection = Connection::Client::Substitute.build
      connection.close

      policy.control_connection connection

      assert !connection.closed?
    end

    test "Does not close an open connection" do
      connection = Connection::Client::Substitute.build

      policy.control_connection connection

      assert !connection.closed?
    end
  end

  context "Resolving a reconnect policy" do
    test "Exists" do
      policy = Connection::Client::ReconnectPolicy.get :never

      assert policy.is_a?(Connection::Client::ReconnectPolicy)
    end

    test "Does not exist" do
      begin
        Connection::Client::ReconnectPolicy.get :not_a_policy
      rescue Connection::Client::ReconnectPolicy::Error => error
      end

      assert error
    end
  end
end
