# WORK IN PROGRESS, NOTHING TO SEE HERE YET #

### Overview ###

Distribute a list of tasks (shell commands) across different workers (docker containers: possibly running in Docker Swarm).

Aggregate the result workers output to their `stdout` and `stderr`.

The main motivation behind this project is to make `rspec` run in parallel.

### How it's supposed to work ###

### Process overview ###

#### Pre-requisites ####

* `docker`
* Docker image for worker

#### Workflow ####

* start rabbitmq (container)
* start manager (create the queue)
* start containerized workers (subscribe to the queue)
* manager pushes commands to the queue
* workers pick up command and execute them
* once command execution is done the exit_code, and contents of stderr and stdout are pushed back to master via rabbitmq
* returned results are processed on master side
* stop and remove containers when all commands are completed

### API ###

```
# start rabbit first
# start bunch of workers

############
# WORKER API

worker = Radagast::Worker.new(rabbit_url, key)
worker.start

#############
# MANAGER API

manager = Radagast::Manager.new(rabbit_url, key)

manager.run('ls', tag: 1, more_meta: 'asd') do |stdout, stderr, exit_code, meta|
  # bla bla bla
end

manager.run('pwd')

manager.finish do |aggregated_results|
  # bla bla bla
end

# stop the workers
# stop rabbit

```

### Links ###

* https://github.com/dry-rb/dry-configurable
* https://github.com/swipely/docker-api
* http://rubybunny.info/articles/connecting.html
