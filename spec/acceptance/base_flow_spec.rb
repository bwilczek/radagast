require 'logger'

require_relative '../../lib/radagast/manager.rb'
require_relative '../../lib/radagast/worker.rb'

RSpec.describe 'End-to-end flow' do
  before(:all) do
    # TODO: spin up rabbitmq container at guest:guest@localhost:5672
  end

  after(:all) do
    # TODO: kill rabbitmq container
  end

  it 'processes simple tasks with one worker' do
    # SETUP
    @config = Radagast::Config.new
    @config.log_level = Logger::UNKNOWN
    # @config.log_file = '/tmp/radagast.log'
    @manager = Radagast::Manager.new @config
    @worker = Radagast::Worker.new @config

    @manager.start

    # Worker is single-threaded and blocking. Extract it to a thread here.
    @worker_thread = Thread.new { @worker.start }

    # THE ACTUAL TEST
    @manager.task 'echo test1' do |result|
      expect(result.exit_code).to eq 0
      expect(result.stdout).to eq 'test1'
      expect(result.stderr).to eq ''
    end

    @manager.task 'echo test2', some_tag: :some_value

    @manager.finish do |results|
      expect(results.length).to eq 2
    end

    # CLEANUP
    @worker.finish
    @worker_thread.join
  end
end
