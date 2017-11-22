require 'json'
require 'open3'

require_relative 'config'
require_relative 'rabbit_helper'

module Radagast
  # Fetches the task, processes it and returns the result
  class Worker < RabbitHelper
    def initialize(config = Radagast::Config.new)
      super(
        queue_name: "tasks-#{config.key}",
        routing_key: "results-#{config.key}",
        config: config
      )
    end

    def start
      connect
      logger.info "Worker setup, subscribing to tasks queue #{@queue.name}"
      subscribe do |data|
        process_task(data)
      end
    end

    def finish
      logger.info 'Finishing worker'
      cleanup
    end

    private

    def process_task(data)
      stdout, stderr, status = Open3.capture3(data['cmd'])
      response = {
        task_id: data['task_id'],
        meta: data['meta'].merge(cmd: data['cmd']),
        stdout: stdout.strip,
        stderr: stderr.strip,
        exit_code: status.exitstatus
      }
      publish(response)
    end
  end
end
