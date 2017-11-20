### Overview ###

Distribute a list of tasks (shell commands) across different workers, running as separate applications.

Aggregate the result workers output to their `stdout` and `stderr`.

The main motivation behind this project is to make `rspec` run in parallel.

### Generic workflow ###

* start RabbitMQ
* start worker(s) - separate process(es)
* start manager (programatically)
* manager pushes commands to the queue
* workers pick up command and execute them
* once command execution is done the output is returned to manager via RabbitMQ
* returned results are processed on manager's side
* stop workers when all commands are completed
* stop RabbitMQ if it's not needed anymore

### Use cases ###

#### Pre-requisites ####

* `RabbitMQ` is available at default location: `amqp://user:pass@host:5672`
* `radagast` gem has been installed

#### Manager and a single worker ####

```
# start the worker
radagast
```

```
# Example manager code (see examples/basic.rb)

require 'radagast'

manager = Radagast::Manager.new
manager.start

manager.task 'echo test1' do |result|
  puts result.exit_code  # 0
  puts result.stdout     # "test1"
  puts result.stderr     # ""
end

manager.task 'cat /etc/shadow' do |result|
  puts result.exit_code  # 1
  puts result.stdout     # ""
  puts result.stderr     # "cat: /etc/shadow: Permission denied"
end

manager.finish do |results|
  puts results.count     # 2
end
```

#### Manager and multiple workers ####

under construction

#### Running rspec ####

under construction

#### dockerizing workers ####

under construction

### API ###

under construction

### Configuration ###

under construction

##### Resources #####

* http://rubybunny.info/articles/connecting.html
