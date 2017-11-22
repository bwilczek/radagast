require 'securerandom'

require_relative 'config'
require_relative 'rabbit_helper'
require_relative 'result'

module Radagast
  # Dispatches tasks and aggregates the results
  class Manager < RabbitHelper
    def initialize(config = Radagast::Config.new)
      super(
        queue_name: "results-#{config.key}",
        routing_key: "tasks-#{config.key}",
        config: config
      )
      @callbacks = {}
      @processed_cnt = 0
      @published_cnt = 0
      @all_results = []
    end

    def task(cmd, meta = {}, &blk)
      logger.info 'Publishing task'
      @published_cnt += 1
      task_id = SecureRandom.uuid
      @callbacks[task_id] = blk if block_given?
      publish(cmd: cmd, meta: meta, task_id: task_id)
    end

    def finish
      logger.info 'Finishing manager'
      @t.join
      yield @all_results if block_given?
    end

    def start
      connect
      @t = Thread.new do
        logger.info 'Manager subscribe to results queue'
        subscribe do |data|
          process_result(data)
        end
      end
    end

    private

    def process_result(data)
      @processed_cnt += 1
      result = Result.from_hash data
      process_callback result
      @all_results << result
      if @processed_cnt == @published_cnt
        logger.info "All #{@processed_cnt} messages have been processed"
        # TODO: Evaluate how to cancel subscription here instead of closing
        # connection. cleanup call belongs more to #finish
        cleanup
      end
    end

    def process_callback(result)
      logger.info "Result #{@processed_cnt}/#{@published_cnt} : #{result}"
      @callbacks[result.task_id].call(result) if @callbacks.key? result.task_id
    end
  end
end
