require 'pp'
require 'logger'

# for development:
require_relative '../lib/radagast/config'
require_relative '../lib/radagast/manager'
# for production:
# require 'radagast'

config = Radagast::Config.new
config.log_level = Logger::UNKNOWN
manager = Radagast::Manager.new config

manager.start

manager.task 'echo test1' do |result|
  puts 'Process results 1'
  pp result
end

manager.task 'cat /etc/shadow' do |result|
  puts 'Process results 2'
  pp result.meta['cmd']
end

manager.finish do |results|
  puts 'Process aggregated results'
  pp results
end
