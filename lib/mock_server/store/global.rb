require 'hashie'

module MockServer
  module Store

      def mock_server_options_merge(opt = {})
        $mock_server_options ||= MockServer::State.new(opt)
        $mock_server_options.merge!(opt)
      end

      def mock_server_options_read
        $mock_server_options ||= MockServer::State.new
        $mock_server_options
      end

      def mock_server_options_write(value)
        $mock_server_options ||= MockServer::State.new
        $mock_server_options = value
      end

  end
end