module Radagast
  Result = Struct.new(:exit_code, :stdout, :stderr, :meta, :task_id)
end
