require_relative '../../lib/radagast/worker.rb'

RSpec.describe Radagast::Worker do
  describe '#process_task' do
    it 'publishes the result' do
      worker = Radagast::Worker.new
      allow(worker).to receive(:publish)
      input = {
        'cmd' => 'echo test',
        'task_id' => 123,
        'meta' => {}
      }
      output = {
        task_id: 123,
        meta: { cmd: 'echo test' },
        stderr: '',
        stdout: 'test',
        exit_code: 0
      }
      worker.send :process_task, input
      expect(worker).to have_received(:publish).with(output)
    end
  end
end
