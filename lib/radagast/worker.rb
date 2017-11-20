require 'json'
require 'open3'

require_relative 'config'
require_relative 'rabbit_helper'

module Radagast
  # Fetches the task, processes it and returns the result
  class Worker < RabbitHelper
    def initialize(config)
      super(
        queue_name: "tasks-#{config.key}",
        routing_key: "results-#{config.key}",
        config: config
      )
    end

    def start
      logger.info 'Worker setup, subscribing to tasks queue'
      subscribe do |data|
        stdout, stderr, status = Open3.capture3(data['cmd'])
        response = {
          cmd: data['cmd'],
          meta: data['meta'],
          stdout: stdout,
          stderr: stderr,
          exitstatus: status.exitstatus
        }
        publish(response)
      end
    end

    def finish
      logger.info 'Finishing worker'
      cleanup
    end
  end
end
