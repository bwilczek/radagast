require_relative '../../lib/radagast/manager.rb'
require_relative '../../lib/radagast/worker.rb'

RSpec.describe 'End-to-end flow' do
  before(:all) do
    # TODO: spin up rabbitmq container at guest:guest@localhost:5672
  end

  after(:all) do
    # TODO: kill rabbitmq container
  end

  before(:each) do
    @config = Radagast::Config.new
    @manager = Radagast::Manager.new @config
    @worker = Radagast::Worker.new @config

    @manager.start

    # Worker is single-threaded and blocking. Extract it to a thread here.
    @worker_thread = Thread.new { @worker.start }
  end

  after(:each) do
    @worker.finish
    @worker_thread.join
  end

  it 'processes simple tasks with one worker' do
    @manager.task 'echo test1' do |result|
      expect(result.exit_code).to eq 0
      expect(result.stdout).to eq 'test1'
      expect(result.stderr).to eq ''
    end

    @manager.task 'echo test2' do |result|
      expect(result.exit_code).to eq 0
      expect(result.stdout).to eq 'test2'
      expect(result.stderr).to eq ''
    end

    @manager.finish do |results|
      expect(results.length).to eq 2
    end
  end
end
