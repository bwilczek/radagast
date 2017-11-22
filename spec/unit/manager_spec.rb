require_relative '../../lib/radagast/manager.rb'
require 'logger'

RSpec.describe Radagast::Manager do
  let(:result_hash) do
    {
      task_id: 123,
      meta: { cmd: 'echo test' },
      stderr: '',
      stdout: 'test',
      exit_code: 0
    }
  end

  before(:each) do
    @manager = Radagast::Manager.new
    @manager.logger.level = Logger::UNKNOWN
  end

  describe '#task' do
    it 'increments @published_cnt' do
      allow(@manager).to receive(:publish)
      expect do
        @manager.task 'hello kitty!'
      end.to change { @manager.instance_variable_get :@published_cnt }.by(1)
    end
  end

  describe '#process_result' do
    it 'increments @processed_cnt' do
      allow(@manager).to receive(:cleanup)
      expect do
        @manager.send :process_result, result_hash
      end.to change { @manager.instance_variable_get :@processed_cnt }.by(1)
    end

    it 'adds result to @all_results' do
      allow(@manager).to receive(:cleanup)
      expect do
        @manager.send :process_result, result_hash
      end.to change { @manager.instance_variable_get(:@all_results).size }.by(1)
    end
  end
end
