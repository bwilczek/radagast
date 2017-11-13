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
commands = [
  'pwd',
  'ls',
  'whoami'
]

rabbit_container = Docker::Container.create('rabbitmq').start

master = Radagast::Manager.new do |config|
  config.rabbit_url = "guest:guest@localhost:5672/"
end

Radagast::WorkerPool::Docker.start(5, master.config.key, Docker::Container.create('app:v17.4'))

commands.each do |cmd|
  master.run(cmd, tag: :standard) do |stdout, stderr, exit_code, meta|
    puts meta[:cmd], stdout
  end
end

master.run('ls /etc/nosuchfile', tag: :custom) do |stdout, stderr, exit_code, meta|
  puts stderr, exit_code
end

master.wait do
  # post processing logic
end

# destroy rabbit and worker containers
```

### Stack mode ###

```
stack = Radagast::Stack.new do |config|
  config.docker_image = 'app:v17.4'
  on_task = lambda do |stdout, stderr, exit_code, meta|
  end
  on_finish = lambda do
  end
end

stack.run
```

### Links ###

* https://github.com/dry-rb/dry-configurable
* https://github.com/swipely/docker-api
