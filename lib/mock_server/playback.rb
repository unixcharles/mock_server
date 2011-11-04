require 'mock_server/utils'

module MockServer
  class Playback
    include MockServer::Utils

    def initialize(app, options = {})
      @options = options
      @app = app
      $mock_server_options ||= options
    end

    def call(env)
      @options.merge!($mock_server_options)

      verbose(env, $mock_server_options) if @options[:verbose]
      return @app.call(env) unless @options[:routes] and
                                   lazy_match @options[:routes], env["PATH_INFO"]

      @request = Rack::Request.new(env)
      @data = load_data

      record = match_request

      if record
        $mock_server_options[:success_stack] ||= []
        $mock_server_options[:success_stack] << @request.path

        response = record[:response]
        [response[:status], response[:headers], [response[:body]]]
      else
        $mock_server_options[:errors_stack] ||= []
        error = { @request.path => "Couldn't match #{@request.request_method} #{@request.path}" }
        $mock_server_options[:errors_stack] << error
        [404, {}, ['RECORD NOT FOUND!']]
      end
    end

    private

    def match_request
      request = Hashie::Mash.new hashified_request

      # Filter out data records by path and method
      @data.select! { |record|
        record[:request][:path] == request[:path] and record[:request][:method] == request[:method]
      }

      # Filter out matchers by path and method
      matchers = @options[:matchers].select { |match| 
        request[:method].to_s.upcase == match[:method].to_s.upcase and request[:path] == match[:path]
      }

      # Match the request with a record by validating against the matcher if any.
      @data.detect { |entry|
        recorded_request = Hashie::Mash.new entry[:request]

        matchers.detect { |matcher|
          if matcher[:matcher]
            matcher[:matcher].call(request, recorded_request) rescue false
          else
            true
          end
        }
      }
    end

  end
end