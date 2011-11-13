module MockServer
  module Utils

    private

    def verbose(env, options)
      if options
        interception = lazy_match(options[:routes], env["PATH_INFO"]) ? "intercepted!" : "NOT intercepted."
        puts %([MockServer] #{env["PATH_INFO"]} was #{interception}"\n)
      end
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

      json = JSON.parse(body) rescue ''

      {
        :method  => @request.request_method,
        :path    => @request.path,
        :query   => @request.query_string,
        :body    => json
      }
    end
  
    def hashify_response(response)
      status  = response[0]
      headers = response[1]
      body    = response[2].body rescue ''

      {
        :method  => @request.request_method,
        :path    => @request.path,
        :status  => status,
        :headers => headers,
        :body    => body
      }
    end
  end
end
