begin 
  require_relative 'spec_helper'
rescue NameError
  require File.expand_path('spec_helper', __FILE__)
end

require File.expand_path('../../lib/mock_server/record', __FILE__)
require File.expand_path('../../lib/mock_server/utils', __FILE__)

include Rack::Test::Methods

$tmp_path = File.join(File.dirname(__FILE__), 'tmp')

def app
  MockServer::Record.new( MockServer::Test.new, {
    :path => $tmp_path + '/records',
    :filename => 'test',
    :routes => [ '/hello.json' ] })
end

describe "Record" do

  after do
    FileUtils.rm_rf $tmp_path
  end

  it "return the response" do
    get '/hello.json'
    assert_equal '{"message":"world"}', last_response.body
  end

  it "record response body" do
    get '/hello.json'
    load_records

    refute_empty @records
    assert_equal '{"message":"world"}', @records.first[:response][:body]
  end

  it "record request query" do
    get '/hello.json?with=params'
    load_records

    assert_equal "with=params", @records.first[:request][:query]
  end

  it "record request method" do
    put '/hello.json'
    load_records

    assert_equal 'PUT', @records.first[:request][:method]
  end

  it "parse request json body and record the result" do
    post '/hello.json', {"test" => "content"}.to_json, :format => :json
    load_records


    assert_equal 'content', @records.last[:request][:body]['test']
  end


  def load_records
    @records = YAML.load_file(File.join($tmp_path, 'records/test.yml'))
  end
end