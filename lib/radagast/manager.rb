require 'securerandom'

require_relative 'config'
require_relative 'rabbit_helper'
require_relative 'result'

module Radagast
  # Dispatches tasks and aggregates the results
  class Manager < RabbitHelper
    def initialize(config)
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
      @callbacks[cmd] = blk if block_given?
      publish(cmd: cmd, meta: meta, task_id: SecureRandom.uuid)
    end

    def process_callback(data)
      logger.info "Result #{@processed_cnt}/#{@published_cnt} is here: #{data}"
      result = Result.new
      result.exit_code = data['exit_code']
      result.stderr = data['stderr']
      result.stdout = data['stdout']
      result.meta = data['meta']
      result.task_id = data['task_id']
      @callbacks[result.task_id].call(result) if @callbacks.key? result.task_id
    end

    def finish
      logger.info 'Finishing manager'
      @t.join
      yield @all_results if block_given?
    end

    def start
      @t = Thread.new do
        logger.info 'Manager subscribe to results queue'
        subscribe do |data|
          @processed_cnt += 1
          process_callback data
          @all_results << data
          if @processed_cnt == @published_cnt
            logger.info "All #{@processed_cnt} messages have been processed"
            cleanup
          end
        end
      end
    end
  end
end
