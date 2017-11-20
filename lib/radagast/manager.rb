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
      puts "Publishing task"
      @published_cnt += 1
      @callbacks[cmd] = blk
      publish(cmd: cmd)
    end

    def process_data_callback(data)
      puts "Result #{@processed_cnt}/#{@published_cnt} has arrived: #{data}"
      result = Result.new
      result.exit_code = data['exitstatus']
      result.stderr = data['stderr'].strip
      result.stdout = data['stdout'].strip
      result.meta = {cmd: data['cmd']}
      @callbacks[data['cmd']].call result
    end

    def finish
      puts "Finishing master"
      @t.join
      yield @all_results if block_given?
    end

    def start
      @t = Thread.new do
        @queue.subscribe(block: true) do |delivery_info, metadata, payload|
          puts "Manager subscribe to queue"
          @processed_cnt += 1
          data = JSON.parse(payload)
          @all_results << data
          process_data_callback(data)
          if @processed_cnt == @published_cnt
            puts ""
            puts "Aggregate the results (size: #{@all_results.length})"
            puts " > with non-zero exit code: #{@all_results.count {|i| i['exitstatus'] != 0}}"
            puts "... and exit manager"
            cleanup
          end
        end
      end
    end
  end
end
