require 'bunny'
require 'json'

module Radagast
  # Wraps RabbitMQ internals to provide simple API to Worker and Manager
  class RabbitHelper
    def initialize(queue_name:, routing_key:, config:)
      @rabbit = Bunny.new config.rabbit
      @rabbit.start
      @routing_key = routing_key
      @channel = @rabbit.create_channel
      @exchange = @channel.default_exchange
      @queue = @channel.queue(queue_name, auto_delete: true)
    end

    def cleanup
      @rabbit.close
    end

    def publish(data)
      @exchange.publish(JSON.generate(data), :routing_key => @routing_key)
    end
  end
end
