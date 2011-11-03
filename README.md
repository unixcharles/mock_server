# MockServer

So you have spec for your models and controller for your API.
Now you're building a neat javascript application that consumer that JSON.
And you're going to test it with something like capybara?
The thing is that its going to be slow! And you're testing testing all you're application logic again!

MockServer allow you to record your interaction with the server and give you a way to match
the record request with the real request. Its like a rack [VCR](https://github.com/myronmarston/vcr) for your own API!

# Recording mode

Create mount the rack application, in rails

    require 'mock_server/record'
    config.middleware.use MockServer::Record, { :path => 'fixtures/records', :filename => 'uploads'
                                               :routes => [ '/api/*/**', '/api/*/**' ] }

And you're ready to record. Run the test, build so seed by clicking around. whatever.

# Playback mode

    require 'mock_server/playback'
    config.middleware.use MockServer::Playback, { :path => 'fixtures/records' ] }

Recording your own playback? Noes, don't use the two Rack middleware at the same time.

# Rspec

    require 'mock_server/spec/helpers'
    RSpec.configure do |config|
      config.include MockServer::Spec::Helpers
    end

In your spec

    before :each do

      # Set the filename where you store the records
      mock_server_use_record 'uploads'

      # From now on, those path belong to MockServer.
      #
      # if we can't match to a record, the server return a 404 and populate the errors stack.
      mock_server_enable_routes '**/uploads/*', '**/uploads', '**/folders'

    end

    after :each do
      mock_server_disable_all_routes!
      mock_server_clear_matchers!
      mock_server_response_stack_clear!
    end

    scenario "Some json api fun" do
      mock_server_get('/api/2/projects')
      mock_server_post('/api/2/projects') do |request, recorded_request|

        # I use the should helpers because it return the method
        # but it won't raise a failure in the test, since it happen
        # inside a proc ouside the scenario. But It will populate the
        # error stack if can't match anything.

        recorded_request.body.name.should == recorded_request.body.name and
        recorded_request.body.name.should == 'MockServer'

        # Its a normal detect block, so it has to return true to match
        # the record response.
      }

      ... fun stuff ...

      mock_server_success_stack.should include('/api/2/projects')
      mock_server_errors_stack.should be_empty
    end

# Pull request?

Yes.