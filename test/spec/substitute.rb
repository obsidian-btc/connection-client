require_relative './spec_init'

context 'Client Substitute' do
  data = Connection::Controls::Data.example

  context 'Reading' do
    connection = Connection::Client::Substitute.build
    connection.expect_read data

    output = connection.read

    assert output == data
  end

  context 'Writing' do
    connection = Connection::Client::Substitute.build
    connection.expect_write data

    connection.write data
  end

  context 'EOF' do
    connection = Connection::Client::Substitute.build
    connection.eof

    output = connection.gets

    assert output == nil
  end
end
