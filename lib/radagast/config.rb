require 'optparse'

module Radagast
  Config = Struct.new(:key, :rabbit, :test, :manager, :worker) do
    def initialize
      self.key = 'default'
      self.rabbit = 'amqp://guest:guest@127.0.0.1:5672'
    end

    def self.parse_argv(argv = ARGV)
      config = new
      OptionParser.new do |opt|
        opt.on('--key KEY') { |o| config.key = o }
        opt.on('--rabbit RABBIT') { |o| config.rabbit = o }
        opt.on('--test') { |_o| config.test = true }
        opt.on('--worker') { |_o| config.worker = true }
        opt.on('--manager') { |_o| config.manager = true }
      end.parse!(argv)
      config
    end
  end
end
