Gem::Specification.new do |s|
  s.name        = 'mock_server'
  s.version     = '0.4.1'
  s.summary     = "Mock you're entire application"
  s.authors      = ['Charles Barbier', 'Saimon Moore', 'Ferran Basora']
  s.email       = 'unixcharles@gmail.com'
  s.homepage    = 'http://www.github.com/unixcharles/mock_server'

  s.files        = Dir['README.md', 'LICENSE', 'lib/mock_server.rb',
                       'lib/mock_server/record.rb', 'lib/mock_server/playback.rb',
                       'lib/mock_server/utils.rb', 'lib/mock_server/state.rb', 'lib/mock_server/store/global.rb',
                       'lib/mock_server/spec/helpers.rb']

  s.require_path = 'lib'

  s.add_runtime_dependency 'rack'
  s.add_runtime_dependency 'hashie'
end
