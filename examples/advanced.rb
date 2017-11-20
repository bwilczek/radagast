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

# do NOT processs each single command result with provided block
manager.task 'echo test'
manager.task 'id'
manager.task 'ls -la'
# use tagging to make processing of all results easier
manager.task 'ls -la /no/such/path', expect_error: true
manager.task 'cat /etc/shadow', expect_error: true
manager.task 'ruby -v'

manager.finish do |results|
  puts 'Error summary:'
  puts "got      : #{results.count { |r| r.exit_code != 0 }}"
  puts "expected : #{results.count { |r| r.meta.key? 'expect_error' }}"
end
