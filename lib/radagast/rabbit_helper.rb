require 'bunny'
require 'json'
require 'logger'

module Radagast
  # Wraps RabbitMQ internals to provide simple API to Worker and Manager
  class RabbitHelper
    attr_reader :logger

    def initialize(queue_name:, routing_key:, config:)
      @rabbit = Bunny.new config.rabbit
      @rabbit.start
      @routing_key = routing_key
      @channel = @rabbit.create_channel
      @exchange = @channel.default_exchange
      @queue = @channel.queue(queue_name, auto_delete: true)
      @logger = Logger.new(STDOUT)
      @logger.level = config.log_level
    end

    def cleanup
      @rabbit.close
    end

    def publish(data)
      logger.info "publishing #{data}"
      @exchange.publish(JSON.generate(data), routing_key: @routing_key)
    end

    def subscribe
      @queue.subscribe(block: true) do |_delivery_info, _metadata, payload|
        data = JSON.parse(payload)
        logger.info "processing #{data}"
        yield data
      end
    end
  end
end
