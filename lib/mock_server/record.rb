require 'mock_server/utils'
require 'mock_server/state'

unless defined? MockServer::Store
  require 'mock_server/store/global'
end

class MockServer::Record
  include MockServer::Utils
  include MockServer::Store

  def initialize(app, opt = {})
    @app = app
    @options = mock_server_options_merge(opt)
  end

  def call(env)
    @options = self.mock_server_options_read

    verbose(env) if @options[:verbose]
    return @app.call(env) unless matchable_request?(env)

    @request = Rack::Request.new(env)
    @data = load_data

    @app.call(env).tap do |status, header, response|
      record_response(status, header, response)
      self.mock_server_options_write(@options)
      response
    end
  end

  private

  def record_response(status, header, response)
    request = hashified_request

    @data << { :request => request, :response => hashify_response(status, header, response) }
    save_data(@data)
  end

  def records_path
    File.join( @options[:path], @options[:filename] + '.yml' )
  end

  def save_data(data)
    File.open(records_path, 'w') do |f|
      YAML.dump(data, f)
    end
  end

  def load_data
    FileUtils.mkdir_p(@options[:path]) unless File.exists? @options[:path]

    data = YAML.load_file(records_path) rescue []

    if data.is_a? Array
      data
    else
      []
    end
  end
end