ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'

module MockServer
  class Test
    def initialize(app = nil)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      file_path = File.join(File.dirname(__FILE__), 'fixtures/' + request.path)
      fixture = File.open(file_path)
      [200, {'Content-Type' => 'application/json'}, [fixture.read]]
    end
  end
end