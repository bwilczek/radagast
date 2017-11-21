### Overview ###

Distribute a list of tasks (as shell commands) across different workers (local or remote).

Aggregate the commands' output (stdout, stderr, exit_code)

The main motivation behind this project is to make `rspec` run in parallel and distributed.

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

* `radagast` gem has been installed
* `RabbitMQ` is available at default location: `amqp://guest:guest@localhost:5672`

To easily spin up `RabbitMQ` locally please see scripts in `bin/rabbit-*.sh`.

#### Manager and a single local worker ####

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

#### Scaling Workers with Docker (Swarm) ####

*WARNING: THIS PART HAS NOT BEEN FULLY TESTED YET*

Docker image to be used as a `Worker` has to include:

* radagast command (e.g. installed via `bundler` among other `gems`)
* the software required to run the commands requested by `Manager`

Once these requirements are met `Worker` can be started with a command like this:

```bash
docker run -d \
  --entrypoint /path/to/radagast \
  --name radagast-worker-myapp-1 \
  myapp:v17.2.1 \
  --rabbit amqp://user:password@rabbit.intranet:5672
```

Where `myapp:v17.2.1` is the docker image name, and the lines below it (command passed to container)
contains the arguments for `radagast` command passed as the `--entrypoint`.

Multiple containers can be spawned this way, please just make sure that `--name` is unique.

Set up `docker swarm` to distribute workers across multiple nodes. No changes on `radagast` end are required.
`docker run` will automatically spawn workers on other network nodes as long as the environment variable `DOCKER_HOST`
points to a properly configured `docker swarm`.

### API ###

At this stage Radagast consists of only a few classes with a pretty straight-forward API.

##### Config #####

A `Struct` containig the following fields (with defaults):

```ruby
key = 'default'            # prefix used for RabbitMQ queue name. Optional, use with shared RabbitMQ instance
rabbit = 'amqp://guest:guest@127.0.0.1:5672'
log_level = Logger::INFO   # config for Logger
log_file = STDOUT          # config for Logger
```

When starting `Worker` via CLI with `radagast` command the following switches are supported and mapped into the `Config` instance.

```bash
--key KEY                  # prefix used for RabbitMQ queue name. Optional, use with shared RabbitMQ instance
--rabbit RABBIT            # rabbitmq URL
--log_level LOG_LEVEL      # has to properly evaluate by const_get. Example: Logger::DEBUG
--log_file LOG_FILE        # path to log file. Default is STDOUT (as seen above)
```

See [RabbitMQ docs](http://rubybunny.info/articles/connecting.html) for format of `--rabbit` URL.

##### Manager #####

```ruby
# constructor
manager = Radagast::Manager.new config   # config is a Radagast::Config instance
manager = Radagast::Manager.new          # use default Config values

# start listening to results queue
manager.start

# publish task, don't care about the result yet
manager.task 'rspec --tag unit'

# publish task, tag it for better filtering of complete results list
manager.task 'rspec --tag unit', my_tag: 'my_value', other_tag: 2

# publish task, pass a block to process the result
manager.task 'rspec --tag unit' do |result|
  # result is an instance of Radagast::Result
  puts "Got some errors: #{result.stderr}" unless result.exit_code == 0
end

# wait for all results to arrive and process them
manager.finish do |results|
  # results is an array of Radagast::Result
  puts "Number of non-zero exit codes: #{results.count { |r| r.exit_code != 0 }}"
end
```

##### Result #####

A `Struct` containig the following fields:

```bash
exit_code  # exit code from command execution
stdout     # command's output to stdout
stderr     # command's output to stderr
meta       # a hash of tags passed to Manager#task metod plus the 'cmd'
task_id    # used internally as an ID to handle callbacks
```

##### Worker #####

In case one would need to start the `Worker` programatically.

```ruby
# constructor
worker = Radagast::Worker.new config   # config is a Radagast::Config instance
worker = Radagast::Worker.new          # use default Config values

# start listening to tasks queue and react on incoming tasks
worker.start

# stop listening and do the clean up
worker.finish
```

See `Config` section above to learn how to configure worker executed from CLI.

### Final thoughts ###

* The project is an early pre-beta. It has not been tested in production.
* It has been barely tested in development.
* Feel free to play around, submit bugs and features though

##### Why Radagast? #####

To honor Radagast the Brown: the first wizard who employed rabbits to move faster.
