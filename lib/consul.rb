require 'consul/version'

module Consul
  # Your code goes here...

  Error = Class.new(StandardError)
end

require 'consul/api'
require 'consul/session'
require 'consul/kv'
