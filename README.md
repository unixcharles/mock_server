MockServer
----------

MockServer let you record interactions with Rack-apps and provide playback with advanced request matching for your tests.

Its a solution to a real world problem that came up at [Teambox](http://teambox.com) where we use it extensively for our acceptance test suite.

When building javascript application that communicate with the backend over an API, you will find yourself testing the entire stack again and again, waiting after the database while you only want ensure that your javascript applicatin is correctly communicating with the server.

Our solution was to considere our own backend as it was an external service and completely mock the API interaction.

### Speed. Its fast.

Run test against a completely fake server, don't hit you application stack.

### Test isolation.

Avoid duplicated testing. Test your API in its own test suite and let the frontend perform request against fixtures to avoid testing the entire stack (again).

## How it work

MockServer is a very light solution with three parts.

* a recording Rack middleware
* a playback Rack middleware
* an helper module to use inside your tests

Getting started
---------------

### Installation

```bash
gem install mock_server
```

### Recording mode

Mounting the rack middleware, in rails

```ruby
require 'mock_server/record'
config.middleware.use MockServer::Record,
  { :path => 'fixtures/records', :filename => 'api'
    :routes => [ '/api/*/**', '/api_v2/**' ] }
```

At this point, the `MockServer::Record` middleware will record all the intraction that match the given routes into the `fixtures/records/api.yml` file.

You can record from your test or just boot the app and click around, be creative.

### Playback mode

Once you are done recording, disable the `MockServer::Record`. You are ready to use the `MockServer::Playback` middleware.

```ruby
require 'mock_server/playback'
config.middleware.use MockServer::Playback,
  { :path => 'fixtures/records' }
```

You are now ready to test.

### Rspec

MockServer come with an helper module to load fixture, listen to paths and register matchers.

You just need to include the module in your test.

For exemple, in Rspec, you could do like this:

```ruby
require 'mock_server/spec/helpers'
RSpec.configure do |config|
  config.include MockServer::Spec::Helpers
end
```

Inside your test, basic usage exemple:

```ruby
before :each do
  # Set the filename where you store the records
  # in this exemple, it will load `fixtures/records/bootsrap.yml`
  # and `fixtures/records/uploads.yml`
  mock_server_use_record 'bootsrap', 'uploads'

  # From now on, those paths belong to MockServer.
  # if we can't find a record with the matchers, the server return a 404 and populate the errors stack.
  mock_server_enable_routes '/api/2/**'
end

after :each do
  mock_server_reset!
end

scenario "Some JSON api fun" do
  mock_server_get('/api/2/projects')
  # If no block is given, it will return the first recorded response that
  # match the verb and path.

  # You can be more specific by using a block
  mock_server_post('/api/2/projects') do |request, recorded_request|

    recorded_request.body.name == recorded_request.body.name and
    recorded_request.body.name == 'MockServer'

    # Internally, the Playback middlware will perform a Array#detect against
    # all the recorded request loaded from the fixture files and will
    # return the response when it return true
  }

  # ...fun stuff... fight with selenium selectors or whatever you would normally do!
end
```

Have a look at the [helpers](http://rubydoc.info/github/unixcharles/mock_server/master/MockServer/Spec/Helpers).

## Pull request?

Yes.

## Documentation

[rubydoc](http://rubydoc.info/github/unixcharles/mock_server/master)

## Credits

MockServer borrow awesome ideas of [VCR](https://github.com/myronmarston/vcr) from [Myron Marston](https://github.com/myronmarston) that does similar work with HTTP interactions to external services.

MockServer actively developped for our internal use at [Teambox](http://teambox.com/). Thanks to my colleges for their insightful feedback and pull requests.