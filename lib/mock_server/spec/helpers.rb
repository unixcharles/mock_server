unless defined? MockServer::Store
  require 'mock_server/store/global'
end

module MockServer::Spec
  module Helpers
    include MockServer::Store


    # Public: Inspect mock server options
    #
    # Returns a String.
    def mock_server_inspect
      mock_server_options.inspect
    end

    # Public: Overwrite or initialize the list of fixtures
    #
    # *arguments - Filename...
    #
    # Examples
    #
    #    mock_server_use_record(:users, :comments)
    #
    def mock_server_use_record(*arguments)
      mock_server_options_set(:record_filenames, arguments)
    end

    # Public: Add fixtures to the list of fixtures
    #
    # *arguments - Filename...
    #
    # Examples
    #
    #    mock_server_add_record(:users, :comments)
    #
    def mock_server_add_record(*arguments)
      config = (mock_server_options_fetch(:record_filenames, []) + arguments)
      mock_server_options_set(:record_filenames, config)
    end

    # Public: Set the path of fixtures files
    #
    # path - Sting of the fixtures path
    #
    # Examples
    #
    #    mock_server_set_fixture_path('fixtures/records/')
    #
    def mock_server_set_fixture_path(path)
      mock_server_options_set(:path, path)
    end

    # Public: Enabled MockServer on a given routes.
    # Accept unix-directory like */** catch all.
    #
    # *arguments - Sting of the fixtures path
    #
    # Examples
    #
    #    mock_server_enable_routes('/api/2/**', '/api/verify')
    #
    def mock_server_enable_routes(*paths)
      routes = mock_server_options_fetch(:routes, []) + paths
      mock_server_options_set(:routes, routes)
    end

    # Public: Disable MockServer on a given routes.
    #
    # *paths - Sting of the fixtures path
    #
    # Examples
    #
    #    mock_server_disable_path('/api/2/**', '/api/verify')
    #
    def mock_server_disable_path(*paths)
      routes = mock_server_options_fetch(:routes, []) - paths
      mock_server_options_set(:routes, routes.flatten)
    end

    # Public: Disable all routes being server by MockServer
    #
    #
    # Examples
    #
    #    mock_server_disable_all_routes!
    #
    def mock_server_disable_all_routes!
      mock_server_options_set(:routes, [])
    end

    # Public: Register a matcher on a GET request for a given route.
    #
    # path    - Relative HTTP path to match
    # &block  - Optional block for complex matching on the request
    #
    # Examples
    #
    #    mock_server_get('/api/2/account')
    #
    #    mock_server_get('/api/2/account') { |request, recorded_request| request.body == recorded_request.body }
    #
    def mock_server_get(path, &block)
      mock_server_request :get, path, block
    end

    # Public: Register a matcher on a POST request for a given route.
    #
    # path    - Relative HTTP path to match
    # &block  - Optional block for complex matching on the request
    #
    # Examples
    #
    #    mock_server_post('/api/2/account')
    #
    #    mock_server_post('/api/2/account') { |request, recorded_request| request.body == recorded_request.body }
    #
    def mock_server_post(path, &block)
      mock_server_request :post, path, block
    end

    # Public: Register a matcher on a PUT request for a given route.
    #
    # path    - Relative HTTP path to match
    # &block  - Optional block for complex matching on the request
    #
    # Examples
    #
    #    mock_server_put('/api/2/account')
    #
    #    mock_server_put('/api/2/account') { |request, recorded_request| request.body == recorded_request.body }
    #
    def mock_server_put(path, &block)
      mock_server_request :put, path, block
    end

    # Public: Register a matcher on a DELETE request for a given route.
    #
    # path    - Relative HTTP path to match
    # &block  - Optional block for complex matching on the request
    #
    # Examples
    #
    #    mock_server_delete('/api/2/account')
    #
    #    mock_server_delete('/api/2/account') { |request, recorded_request| request.body == recorded_request.body }
    #
    def mock_server_delete(path, &block)
      mock_server_request :delete, path, block
    end

    # Public: Clear all the matchers
    #
    def mock_server_clear_matchers!
      mock_server_options_set(:matchers, [])
    end

    # Public: Retrive the MockServer request stack.
    #
    # Return array of request path.
    def mock_server_requests_stack
      mock_server_options_fetch(:requests_stack, [])
    end

    # Public: Clear the MockServer request stack.
    def mock_server_requests_stack_clear!
       mock_server_options_set(:requests_stack, [])
    end

    # Public: Retrive the MockServer request stack.
    #
    # Return array of request path.
    def mock_server_errors_stack
      mock_server_options_fetch(:errors_stack, [])
    end

    # Public: Retrive the MockServer errors request stack.
    # i.e.: path being register for being serve by MockServer, but
    # no suitable matcher was found to serve the request will be
    # added to the error stack
    #
    # Return array of errors.
    def mock_server_errors_stack_clear!
      mock_server_options_set(:errors_stack, [])
    end

    # Public: Retrive the MockServer successful request stack.
    #
    # Return array of successful response stack.
    def mock_server_success_stack
      mock_server_options_fetch(:success_stack, [])
    end

    # Public: Clear the MockServer successful request stack.
    def mock_server_success_stack_clear!
      mock_server_options_set(:success_stack, [])
    end

    # Public: Clear the MockServer response stack.
    #
    # alias:
    #
    #   mock_server_requests_stack_clear!
    #   mock_server_success_stack_clear!
    #   mock_server_errors_stack_clear!
    #
    def mock_server_response_stack_clear!
      mock_server_requests_stack_clear!
      mock_server_success_stack_clear!
      mock_server_errors_stack_clear!
    end

    # Public: Clear the MockServer state.
    #
    # alias:
    #
    #   mock_server_response_stack_clear!
    #   mock_server_clear_matchers!
    #   mock_server_disable_all_routes!
    #
    def mock_server_reset!
      mock_server_response_stack_clear!
      mock_server_clear_matchers!
      mock_server_disable_all_routes!
    end

    # Public: Utility helper to reraise errors catch inside the matchers block
    #
    def mock_server_reraise_matcher_exceptions
      mock_server_options_fetch(:matcher_exceptions, []).each do |exception|
        raise exception
      end
    end

    protected

    # Internal: Register a matcher on a given route for playback
    #
    # method  - HTTP verb to register
    # path    - Relative HTTP path to match
    # matcher - Optional proc for complex matching on the request
    #
    # Examples
    #
    #    mock_server_request(:get, '/api/2/account')
    #
    #    mock_server_request(:get, '/api/2/account', lambda {|request, recorded_request| request.body == recorded_request.body } )
    #
    def mock_server_request(method, path, matcher)
      add_mock_server_matcher({ :method => method, :path => path, :matcher => matcher })
    end

    # Internal: Insert a matcher hash into the matchers array of the MockServer storage class.
    #
    def add_mock_server_matcher(matcher)
      options = self.mock_server_options_read
      options[:matchers].unshift(matcher)
      mock_server_options_write(options)
    end

    # Internal: Fetch key from the storage class
    #
    def mock_server_options_fetch(key, value)
      if self.mock_server_options_read[key]
        mock_server_options_get(key)
      else
        mock_server_options_set(key, value)
      end
    end

    # Internal: Setter for the storage class
    #
    def mock_server_options_set(key, value)
      hash = self.mock_server_options_read
      hash[key] = value
      self.mock_server_options_write(hash)
    end

    # Internal: Getter for the storage class
    #
    def mock_server_options_get(key)
      hash = self.mock_server_options_read
      hash[key]
    end

  end
end
