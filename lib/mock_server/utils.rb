require 'yaml'
require 'json'

module MockServer
  module Utils

    private

    def verbose(env)
      interception = lazy_match(@options[:routes], env["PATH_INFO"]) ? "intercepted!" : "NOT intercepted."
      puts %([MockServer] #{env["PATH_INFO"]} was #{interception}"\n)
    end

    def lazy_match(strings, path)
      regexps = strings.map { |str|
        escaped = Regexp.escape(str)
        escaped.gsub!('\\*\\*', '[\w|.|\-|\/]+')
        escaped.gsub!('\\*', '[\w|.|\-]+')
        Regexp.new("^#{escaped}$")
      }

      regexps.any? { |regex| regex.match(path) }
    end

    def hashified_request
      #rewind to ensure we read from the start
      @request.body.rewind

      #read body
      body = @request.body.read

      #rewind in case upstream expects it rewound
      @request.body.rewind

      json = JSON.parse(body) rescue body

      {
        :method  => @request.request_method,
        :path    => @request.path,
        :query   => @request.query_string,
        :body    => json
      }
    end
  
    def hashify_response(status, header, response)
      {
        :method  => @request.request_method,
        :path    => @request.path,
        :status  => status,
        :headers => header,
        :body    => if response.respond_to? :body
          response.body
        else
          response.join
        end
      }
    end
  end
end
