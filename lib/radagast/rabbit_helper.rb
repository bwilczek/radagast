require 'bunny'
require 'json'
require 'logger'

module Radagast
  # Wraps RabbitMQ internals to provide simple API to Worker and Manager
  class RabbitHelper
    attr_reader :logger

    def initialize(queue_name:, routing_key:, config:)
      @rabbit_url = config.rabbit
      @routing_key = routing_key
      @queue_name = queue_name
      @logger = Logger.new(config.log_file)
      @logger.level = config.log_level
    end

    private

    def connect
      @rabbit = Bunny.new @rabbit_url
      @rabbit.start
      @channel = @rabbit.create_channel
      @exchange = @channel.default_exchange
      @queue = @channel.queue(@queue_name, auto_delete: true)
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
