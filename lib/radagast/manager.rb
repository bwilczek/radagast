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

    def task(cmd, &blk)
      logger.info 'Publishing task'
      @published_cnt += 1
      @callbacks[cmd] = blk
      publish(cmd: cmd)
    end

    def process_callback(data)
      logger.info "Result #{@processed_cnt}/#{@published_cnt} is here: #{data}"
      result = Result.new
      result.exit_code = data['exitstatus']
      result.stderr = data['stderr'].strip
      result.stdout = data['stdout'].strip
      result.meta = { cmd: data['cmd'] }
      @callbacks[data['cmd']].call result
    end

    def finish
      logger.info 'Finishing manager'
      @t.join
      yield @all_results if block_given?
    end

    def start
      @t = Thread.new do
        logger.info 'Manager subscribe to queue'
        subscribe do |data|
          process_callback data
          @all_results << data
          @processed_cnt += 1
          if @processed_cnt == @published_cnt
            logger.info "All #{@processed_cnt} messages have been processed"
            cleanup
          end
        end
      end
    end
  end
end
