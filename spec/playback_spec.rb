require File.expand_path('../spec_helper', __FILE__)
require File.expand_path('../../lib/mock_server/playback', __FILE__)
require File.expand_path('../../lib/mock_server/spec/helpers', __FILE__)

describe "Playback" do
  include Rack::Test::Methods
  include MockServer::Spec::Helpers

  def app
    MockServer::Playback.new( nil, {
      :path => File.dirname(__FILE__) + '/fixtures',
      :record_filenames => ['records'],
      :routes => [ '/**' ] })
  end

  it "return the response" do
    mock_server_get('/hello.json')

    get '/hello.json'

    assert_equal 'world', last_response.body
  end

  it "match request with query params" do
    mock_server_get('/query.json') do |request, recorded_request|
      request.query == recorded_request.query and
      recorded_request.query == 'with=params'
    end

    get '/query.json?with=params'
    assert_equal 'with params', last_response.body
  end

  it "match request with body" do
    mock_server_post('/body.json') do |request, recorded_request|
      request.body == recorded_request.body and
      recorded_request.body == 'with=body'
    end

    post '/body.json', 'with=body'
    assert_equal 'success post with body', last_response.body
  end

  it "parse request with json body" do
    mock_server_post('/json.json') do |request, recorded_request|
      request.body == recorded_request.body and
      recorded_request.body.name == 'test'
    end

    post '/json.json', '{"name":"test"}'
    assert_equal 'success post with body', last_response.body
  end

  it "pass the parse recorded response and pass it to the matcher block" do
    mock_server_get('/json_response.json') do |request, recorded_request, recorded_response|
      recorded_response.body.json == 'content'
    end

    get '/json_response.json'
    assert_equal '{"json":"content"}', last_response.body
  end


  it "give priority to the last registered matcher" do
    @first_matcher = @second_matcher = 'not executed'

    mock_server_get('/json_response.json') do
      @first_matcher = 'executed!'
      true
    end

    mock_server_get('/json_response.json') do
      @second_matcher = 'executed!'
      true
    end

    get '/json_response.json'
    assert_equal @second_matcher, 'executed!'
    assert_equal @first_matcher, 'not executed'
  end

  it "it match with the matcher order when it has multiple recorded request" do
    mock_server_get('/json_duplicated.json') do |request, recorded_request, recorded_response|
      recorded_response.body.duplicated == 1
    end

    mock_server_get('/json_duplicated.json') do |request, recorded_request, recorded_response|
      recorded_response.body.duplicated == 2
    end

    get '/json_duplicated.json'
    assert_equal '{"duplicated":2}', last_response.body
  end
end