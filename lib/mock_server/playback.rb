require 'erb'
require 'hashie'

require_relative 'utils'
require_relative 'state'

unless defined? MockServer::Store
  require_relative 'store/global'
end

module MockServer
  class Playback
    include MockServer::Utils
    include MockServer::Store

    def initialize(app, opt = {})
      @app = app
      @options = mock_server_options_merge(opt)
    end

    def call(env)
      @options = self.mock_server_options_read

      verbose(env) if @options[:verbose]
      return @app.call(env) unless @options[:routes] and
                                   lazy_match @options[:routes], env["PATH_INFO"]

      @request = Rack::Request.new(env)

      @options[:requests_stack] ||= []
      @options[:requests_stack] << @request.path

      @data = load_data

      record = match_request

      response = if record
        @options[:success_stack] ||= []
        @options[:success_stack] << @request.path

        response = record[:response]
        [response[:status], response[:headers], [response[:body]]]
      else
        @options[:errors_stack] ||= []
        error = { @request.path => "Couldn't match #{@request.request_method} #{@request.path}" }
        @options[:errors_stack] << error
        [404, {}, ['RECORD NOT FOUND!']]
      end

      self.mock_server_options_write(@options)
      response
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
            result = true
            begin
              matcher[:matcher].call(request, recorded_request)
            rescue => matcher_err
              store_matcher_exception(matcher_err)
              result = false
            ensure
              result
            end
          else
            true
          end
        }
      }
    end

    def store_matcher_exception(exception)
      @options[:matcher_exceptions] ||= []
      @options[:matcher_exceptions] << exception
    end

    def load_data
      FileUtils.mkdir_p(@options[:path]) unless File.exists? @options[:path]

      data = []

      @options[:record_filenames].map do |filename|
        file_path = File.join( @options[:path], filename + '.yml' )
        content   = File.open(file_path).read
        compiled  = ERB.new(content).result
        parsed    = YAML.load(compiled)
        data     += parsed
      end

      data
    end

  end
end
