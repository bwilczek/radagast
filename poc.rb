require 'pp'
# require 'radagast'

require_relative 'lib/radagast/config'
require_relative 'lib/radagast/manager'

config = Radagast::Config.new
manager = Radagast::Manager.new config

manager.start

manager.task 'echo test1' do |result|
  puts 'Process results 1'
  pp result
end

manager.task 'cat /etc/shadow' do |result|
  puts 'Process results 2'
  pp result
end

manager.finish do |results|
  puts 'Process aggregated results'
  pp results
end
