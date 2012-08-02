require 'hashie'

module MockServer
  class State < Hashie::Dash
    property :path, :default => 'fixtures/records'
    property :filename, :default => 'record'
    property :routes, :default => []
    property :record_filenames, :default => []
    property :matchers, :default => []
    property :verbose, :default => false
    property :requests_stack, :default => []
    property :success_stack, :default => []
    property :errors_stack, :default => []
    property :requests_stack, :default => []
    property :matcher_exceptions, :default => []

    def merge(hash)
      new_hash = self
      hash.each do |k,v|
        new_hash[k] = v
      end
      new_hash
    end

    def merge!(hash)
      hash.each do |k,v|
        self[k] = v
      end
      self
    end
  end
end