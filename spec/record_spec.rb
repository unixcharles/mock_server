['../spec_helper','../../lib/mock_server/record', '../../lib/mock_server/spec/helpers'].each { |file|
  require File.expand_path(file, __FILE__)
}

describe "Record" do
  include Rack::Test::Methods
  include MockServer::Spec::Helpers

  def app
    @tmp_path = File.join(File.dirname(__FILE__), 'tmp')

    MockServer::Record.new( MockServer::Test.new, {
      :path => @tmp_path + '/records',
      :filename => 'test',
      :routes => [ '/hello.json' ] })
  end

  after do
    FileUtils.rm_rf @tmp_path
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
    @records = YAML.load_file(File.join(@tmp_path, 'records/test.yml'))
  end
end