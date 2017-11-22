module Radagast
  Result = Struct.new(:exit_code, :stdout, :stderr, :meta, :task_id) do
    def self.from_hash(data)
      new(
        data['exit_code'],
        data['stdout'],
        data['stderr'],
        data['meta'],
        data['task_id']
      )
    end
  end
end
