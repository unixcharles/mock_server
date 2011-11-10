# The purpose of the helper is to manpulate MockServer global var
# in an rspec way. $mock_server_options
#
#
# The basic:
#
#   $mock_server_options = { :path => 'fixtures/records', :filename => 'uploads' }
#
#
# $mock_server_options tell you application which URL to do its magic for both, 
# record and playback mode.
#
# Example:
#
#   $mock_server_options[:routes] = [ '**/uploads.json', '**/uploads/*',
#                                     '**/folders.json', '**/folders', '**/folders' ]
#
# $mock_server_options[:matchers] is an array of path, url, and matchers proc
#
# Example:
#
# $mock_server_options[:matchers] = [
#   { :method => :get, :path => '/api/2/projects/1/uploads.json',
#     :matcher => Proc.new { |request, recorded_request|
#       request.query == recorded_request.query and
#       request.query == 'count=0'
#     }
#   },
#   { :method => :put, :path => '/api/2/uploads/20',
#     :matcher => Proc.new { |request, recorded_request|
#       request.query == recorded_request.query and
#       request.query == 'count=0'
#     }
#   },
#   { :method => :delete, :path => '/api/2/uploads/20' },
#   { :method => :get, :path => '/api/2/projects/1/folders.json' },
#   { :method => :post, :path => '/api/2/folders',
#     :matcher => Proc.new { |request, recorded_request|
#       request.body.project_id == recorded_request.body.project_id and
#       request.body.project_id == 1 and
#       recorded_request.body.name == recorded_request.body.name and
#       recorded_request.body.name == 'Mockup'
#     }
#   },
#   { :method => :put, :path => '/api/2/uploads/20', 
#     :matcher => Proc.new { |request, recorded_request|
#       request.body.name == recorded_request.body.name
#     }
#   },
#   { :method => :delete, :path => '/api/2/folders/3' }
# ]



module MockServer
  module Spec
    module Helpers

      # Inspect
      def mock_server_inspect
        $mock_server_options.inspect
      end

      # Configuration
      def mock_server_use_record(filename)
        mock_server_config_set(:record_filenames, [filename])
      end

      def mock_server_add_record(*arguments)
        config = mock_server_config_get(:record_filenames) + arguments
        mock_server_config_set(:record_filenames, config)
      end

      def mock_server_set_fixture_path(path)
        mock_server_config_set(:path, path)
      end

      # Active path config
      def mock_server_enable_routes(*arguments)
        $mock_server_options ||= {}
        $mock_server_options[:routes] ||= []
        $mock_server_options[:routes] << arguments
        $mock_server_options[:routes].flatten!
      end

      def mock_server_disable_path(path)
        return unless $mock_server_options and $mock_server_options[:routes]
        $mock_server_options[:routes] = if path.is_an? Array
          path unless path.empty?
        else
          $mock_server_options[:routes] - [path]
        end
      end

      def mock_server_disable_all_routes!
        $mock_server_options[:routes] = nil
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
        mock_server_config_set(:matchers, [])
      end

      # Errors / Success stack

      def mock_server_errors_stack
        $mock_server_options[:errors_stack] || []
      end

      def mock_server_errors_stack_clear!
        $mock_server_options[:errors_stack] = []
      end

      def mock_server_success_stack
        $mock_server_options[:success_stack] || []
      end

      def mock_server_success_stack_clear!
        $mock_server_options[:success_stack] = []
      end

      def mock_server_response_stack_clear!
        mock_server_success_stack_clear!
        mock_server_errors_stack_clear!
      end

      # Clear all the settings

      def mock_server_reset!
        mock_server_response_stack_clear!
        mock_server_clear_matchers!
        mock_server_disable_all_routes!
      end

      protected
      # Configuration
      def mock_server_config_set(key, value)
        $mock_server_options ||= {}
        $mock_server_options[key] = value
      end

      def mock_server_config_get(key)
        $mock_server_options ||= {}
        $mock_server_options[key]
      end

      # Matchers helpers
      def mock_server_request(method, path, matcher)
        add_mock_server_matcher({ :method => method, :path => path, :matcher => matcher })
      end

      def add_mock_server_matcher(matcher)
        $mock_server_options ||= {}
        $mock_server_options[:matchers] ||= []
        $mock_server_options[:matchers] << matcher
      end

    end
  end
end