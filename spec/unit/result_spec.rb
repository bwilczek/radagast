require_relative '../../lib/radagast/result.rb'

RSpec.describe Radagast::Result do
  describe '.from_hash' do
    it 'properly maps entries from given hash' do
      data = {
        'exit_code' => 6,
        'stderr' => 'err',
        'stdout' => 'out',
        'meta' => { k1: :v1, k2: :v2 },
        'task_id' => 123
      }
      result = Radagast::Result.from_hash data
      expect(result.exit_code).to eq(6)
      expect(result.stderr).to eq('err')
      expect(result.stdout).to eq('out')
      expect(result.meta).to include(k1: :v1, k2: :v2)
      expect(result.task_id).to eq(123)
    end
  end
end
