require 'optparse'

module Radagast
  Config = Struct.new(:worker, :manager) do
    def self.parse_argv
      config = Radagast::Config.new
      OptionParser.new do |opt|
        opt.on('--manager') { |o| config.manager = true }
        opt.on('--worker') { |o| config.worker = true }
      end.parse!
      config
    end
  end
end
