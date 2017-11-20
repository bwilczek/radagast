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

* `RabbitMQ` is available at default location: `amqp://guest:guest@localhost:5672`
* `radagast` gem has been installed

#### Manager and a single worker ####

```bash
# start the worker
radagast
```

```ruby
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

#### Manager and multiple workers (hosts) ####

```bash
# run this command on multiple hosts
radagast --rabbit amqp://user:password@rabbit.intranet:5672
```

`Manager` code requires slight adjustments

```ruby
require 'radagast'

config = Radagast::Config.new
config.rabbit = 'amqp://user:password@rabbit.intranet:5672'
manager = Radagast::Manager.new config
manager.start

# the rest remains the same
```

#### Running rspec ####

```ruby
# workers are running and manager is started

# example slicing of rspec test suite by tags.
# Slices will be excecuted paralelly on all connected workers
manager.task 'rspec --format RspecJunitFormatter --tag integration', slice: 1
manager.task 'rspec --format RspecJunitFormatter --tag selenium_subset2', slice: 2
manager.task 'rspec --format RspecJunitFormatter --tag selenium_subset2', slice: 3
manager.task 'rspec --format RspecJunitFormatter --tag performance', slice: 4
manager.task 'rspec --format RspecJunitFormatter --tag unit', slice: 5

manager.finish do |results|
  results.each do |result|
    File.write("results/rspec_slice#{result.meta['slice']}.xml", result.stdout)
  end
end
# now CI engine can merge all XML files stored in results/rspec_slice*.xml
```

#### dockerizing workers ####

under construction

### API ###

##### Config #####

##### Manager #####

##### Result #####

##### Worker #####

Required only to run `Worker` programatically.

### Configuration ###

##### Worker execution #####

##### Manager execution #####

#### Why Radagast? ####

To honor Radagast the Brown: the first wizard who employed rabbits to move faster.

##### Resources #####

* http://rubybunny.info/articles/connecting.html
