unless defined? MockServer::Store
  require_relative 'Store/global'
end

module MockServer
  module Spec
    module Helpers
      include MockServer::Store

      # Inspect
      def mock_server_inspect
        mock_server_options.inspect
      end

      # Configuration
      def mock_server_use_record(*arguments)
        mock_server_options_set(:record_filenames, arguments)
      end

      def mock_server_add_record(*arguments)
        config = (mock_server_options_fetch(:record_filenames, []) + arguments)
        mock_server_options_set(:record_filenames, config)
      end

      def mock_server_set_fixture_path(path)
        mock_server_options_set(:path, path)
      end

      # Active path config
      def mock_server_enable_routes(*arguments)
        routes = mock_server_options_fetch(:routes, []) + arguments
        mock_server_options_set(:routes, routes)
      end

      def mock_server_disable_path(path)
        routes = mock_server_options_fetch(:routes, []) - [path]
        mock_server_options_set(:routes, routes.flatten!)
      end

      def mock_server_disable_all_routes!
        mock_server_options_set(:routes, [])
      end

      # Matchers helpers
      def mock_server_get(path, &block)
        mock_server_request :get, path, block
      end

      def mock_server_post(path, &block)
        mock_server_request :post, path, block
      end

      def mock_server_put(path, &block)
        mock_server_request :put, path, block
      end

      def mock_server_delete(path, &block)
        mock_server_request :delete, path, block
      end

      def mock_server_clear_matchers!
        mock_server_options_set(:matchers, [])
      end

      # Errors / Success stack
      def mock_server_requests_stack
        mock_server_options_fetch(:requests_stack, [])
      end

      def mock_server_requests_stack_clear!
         mock_server_options_set(:requests_stack, [])
      end

      def mock_server_errors_stack
        mock_server_options_fetch(:errors_stack, [])
      end

      def mock_server_errors_stack_clear!
        mock_server_options_set(:errors_stack, [])
      end

      def mock_server_success_stack
        mock_server_options_fetch(:success_stack, [])
      end

      def mock_server_success_stack_clear!
        mock_server_options_set(:success_stack, [])
      end

      def mock_server_response_stack_clear!
        mock_server_requests_stack_clear!
        mock_server_success_stack_clear!
        mock_server_errors_stack_clear!
      end

      # Clear all the settings

      def mock_server_reset!
        mock_server_response_stack_clear!
        mock_server_clear_matchers!
        mock_server_disable_all_routes!
      end

      def mock_server_reraise_matcher_exceptions
        mock_server_options_fetch(:matcher_exceptions, []).each do |exception|
          raise exception
        end
      end

      protected

      # Matchers helpers
      def mock_server_request(method, path, matcher)
        add_mock_server_matcher({ :method => method, :path => path, :matcher => matcher })
      end

      def add_mock_server_matcher(matcher)
        options = self.mock_server_options_read
        options[:matchers] << matcher
        mock_server_options_write(options)
      end

      def mock_server_options_fetch(key, value)
        if self.mock_server_options_read[key]
          mock_server_options_get(key)
        else
          mock_server_options_set(key, value)
        end
      end

      def mock_server_options_set(key, value)
        hash = self.mock_server_options_read
        hash[key] = value
        self.mock_server_options_write(hash)
      end

      def mock_server_options_get(key)
        hash = self.mock_server_options_read
        hash[key]
      end

    end
  end
end
