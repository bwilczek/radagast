require_relative '../../lib/radagast/worker.rb'

RSpec.describe Radagast::Worker do
  describe '#process_data' do
    it 'publishes the result' do
      # create partial stub (stub out publish)
      # process_data(cmd: 'echo test', task_id: 123)
      # expect that publish is called with a specific hash
    end
  end
end
