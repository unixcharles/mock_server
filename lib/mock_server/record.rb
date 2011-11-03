require 'mock_server/utils'

module MockServer
  class Record
    include MockServer::Utils

    def initialize(app, options = {})
      @options = options
      @app = app
      $mock_server_options ||= options
    end

    def call(env)
      return @app.call(env) unless $mock_server_options and
                                   $mock_server_options[:routes] and
                                   lazy_match $mock_server_options[:routes], env["PATH_INFO"]

      @options.merge!($mock_server_options)

      @request = Rack::Request.new(env)
      @data = load_data

      @app.call(env).tap do |response|
        record_response(response)
        response
      end
    end
  
    private
    
    def record_response(response)
      request = hashified_request
      @data.reject! { |record| record[:request] == request }

      @data << { :request => request, :response => hashify_response(response) }
      save_data(@data)
    end

  end
end