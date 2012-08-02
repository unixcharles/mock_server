require 'erb'
require 'hashie'

require 'mock_server/utils'
require 'mock_server/state'

unless defined? MockServer::Store
  require 'mock_server/store/global'
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

      @options[:requests_stack] << @request.path

      @data = load_data

      record = match_request

      response = if record
        @options[:success_stack] << @request.path
        @options[:matcher_exceptions].clear

        response = record[:response]
        [response[:status], response[:headers], [response[:body]]]
      else
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
      data = filter_records(request)

      matchers = filter_matchers(request)

      data = false
      matchers.detect { |matcher|
        # Match the request with a record by validating against the matcher if any.
        data = @data.detect { |entry|
          recorded_request  = Hashie::Mash.new entry[:request]
          recorded_response = entry[:response].dup

          recorded_response[:body] = JSON.parse(recorded_response[:body]) rescue recorded_response[:body]
          recorded_response = Hashie::Mash.new recorded_response

          test_request_and_matcher(matcher, request, recorded_request, recorded_response)
        }
      }
      data
    end

    def filter_matchers(request)
      @options[:matchers].select { |match|
        request[:method].to_s.upcase == match[:method].to_s.upcase and request[:path] == match[:path]
      }
    end

    def filter_records(request)
      @data.select { |record|
        record[:request][:path] == request[:path] and record[:request][:method] == request[:method]
      }
    end

    def test_request_and_matcher(matcher, request, recorded_request, recorded_response)
      return true if matcher[:matcher].nil?
      begin
        matcher[:matcher].call(request, recorded_request, recorded_response) == true
      rescue => matcher_err
        store_matcher_exception(matcher_err)
        false
      end
    end

    def store_matcher_exception(exception)
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
