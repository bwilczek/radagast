require_relative '../../lib/radagast/manager.rb'
require_relative '../../lib/radagast/worker.rb'

RSpec.describe Radagast::Manager do
  it 'processes simple tasks with one worker' do
    # TODO: spin up rabbitmq at guest:guest@localhost:5672
    config = Radagast::Config.new
    manager = Radagast::Manager.new config
    worker = Radagast::Worker.new config

    manager.start

    # Worker is single-threaded and blocking. Extract it to a thread here.
    t = Thread.new { worker.start }

    manager.task 'echo test1' do |result|
      puts "Task 1 result"
      expect(result.exit_code).to eq 0
      expect(result.stdout).to eq 'test1'
      expect(result.stderr).to eq ''
    end

    manager.task 'echo test2' do |result|
      puts "Task 2 result"
      expect(result.exit_code).to eq 0
      expect(result.stdout).to eq 'test2'
      expect(result.stderr).to eq ''
    end

    manager.finish do |results|
      puts "Manager finish"
      puts results.inspect
      expect(results.length).to eq 2
    end

    worker.finish
    t.join
  end
end
