require 'typhoeus'
require 'json'

module Consul
  module APIv1
    CATEGORIES = {}
  end # APIv1
end # Consul

require 'consul/api_v1/kv'
require 'consul/api_v1/agent'
require 'consul/api_v1/catalog'
require 'consul/api_v1/health'
require 'consul/api_v1/session'
require 'consul/api_v1/acl'
require 'consul/api_v1/event'
require 'consul/api_v1/status'
