require 'optparse'

module Radagast
  Config = Struct.new(:key, :rabbit, :test, :manager, :worker) do
    def self.parse_argv
      config = new
      config.key = 'default'
      config.rabbit = 'amqp://guest:guest@127.0.0.1:5672'
      OptionParser.new do |opt|
        opt.on('--key KEY') { |o| config.key = o }
        opt.on('--rabbit RABBIT') { |o| config.rabbit = o }
        opt.on('--test') { |o| config.test = true }
        opt.on('--worker') { |o| config.worker = true }
        opt.on('--manager') { |o| config.manager = true }
      end.parse!
      config
    end
  end
end
