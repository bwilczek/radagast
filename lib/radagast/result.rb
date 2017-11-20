module Radagast
  Result = Struct.new(:exit_code, :stdout, :stderr, :meta, :task_id) do
    def self.from_hash(data)
      o = new
      o.exit_code = data['exit_code']
      o.stderr = data['stderr']
      o.stdout = data['stdout']
      o.meta = data['meta']
      o.task_id = data['task_id']
      o
    end
  end
end
