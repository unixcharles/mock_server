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
      body = JSON.parse(@request.body.to_a.join) rescue ''
      {
        :method  => @request.request_method,
        :path    => @request.path,
        :query   => @request.query_string,
        :body    => body
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

    # File utils
    def records_path
      File.join( @options[:path], @options[:filename] + '.yml' )
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

    def save_data(data)
      File.open(records_path, 'w') do |f|
        YAML.dump(data, f)
      end
    end

  end
end