require 'bunny'
require 'json'
require 'optparse'

options = {}
OptionParser.new do |opt|
  opt.on('--manager') { |o| options[:manager] = true }
  opt.on('--worker') { |o| options[:worker] = true }
end.parse!

connection = {
  host: '127.0.0.1',
  vhost: '/',
  port: '5672',
  user: 'guest',
  pass: 'guest'
}

begin
  puts "Setup..."
  @rabbit = Bunny.new connection
  @rabbit.start

  @channel = @rabbit.create_channel
  @queue_tasks  = @channel.queue('tasks', :auto_delete => true)
  @queue_results  = @channel.queue('results', :auto_delete => true)

  ########## MANAGER ################
  if options[:manager]
    puts "Start manager..."
    @exchange_tasks = @channel.default_exchange

    # master subscribes to results queue
    t = Thread.new do
      puts "Subscribe for results..."
      @queue_results.subscribe(block: true) do |delivery_info, metadata, payload|
        data = JSON.parse(payload)
        puts "Result has arrived: #{data}"
      end
    end

    # publish some example tasks
    puts "Push some tasks..."
    @exchange_tasks.publish(JSON.generate(cmd: 'pwd 1'), :routing_key => 'tasks')
    @exchange_tasks.publish(JSON.generate(cmd: 'whoami 1'), :routing_key => 'tasks')
    @exchange_tasks.publish(JSON.generate(cmd: 'ls 1'), :routing_key => 'tasks')
    @exchange_tasks.publish(JSON.generate(cmd: 'pwd 2'), :routing_key => 'tasks')
    @exchange_tasks.publish(JSON.generate(cmd: 'whoami 2'), :routing_key => 'tasks')
    @exchange_tasks.publish(JSON.generate(cmd: 'ls 2'), :routing_key => 'tasks')
    @exchange_tasks.publish(JSON.generate(cmd: 'pwd 3'), :routing_key => 'tasks')
    @exchange_tasks.publish(JSON.generate(cmd: 'whoami 3'), :routing_key => 'tasks')
    @exchange_tasks.publish(JSON.generate(cmd: 'ls 3'), :routing_key => 'tasks')

    t.join
  end

  ########## WORKER ################
  if options[:worker]
    puts "Start worker..."
    worker_id = rand(100..999)
    @exchange_results = @channel.default_exchange

    @queue_tasks.subscribe(block: true) do |delivery_info, metadata, payload|
      data = JSON.parse(payload)
      puts "Task has arrived: #{data}"
      # do the job and respond with result
      sleep 2
      @exchange_results.publish(JSON.generate(res: "#{worker_id} Result for #{data['cmd']}"), :routing_key => 'results')
    end
  end
rescue SystemExit, Interrupt
  puts 'Closing RabbitMQ connection...'
  @rabbit.close
end
