require 'optparse'
require 'logger'

module Radagast
  Config = Struct.new(:key, :rabbit, :log_level, :log_file) do
    def initialize
      self.key = 'default'
      self.rabbit = 'amqp://guest:guest@127.0.0.1:5672'
      self.log_level = Logger::INFO
      self.log_file = STDOUT
    end

    def self.parse_argv(argv = ARGV)
      config = new
      OptionParser.new do |opt|
        opt.on('--key KEY') { |o| config.key = o }
        opt.on('--rabbit RABBIT') { |o| config.rabbit = o }
        opt.on('--log_level LOG_LEVEL') { |o| config.log_level = const_get(o) }
        opt.on('--log_file LOG_FILE') { |o| config.log_file = o }
      end.parse!(argv)
      config
    end
  end
end
