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

  # publish some example tasks
  puts "Push some tasks..."
  @exchange_tasks.publish(JSON.generate(cmd: 'pwd'), :routing_key => 'tasks')
  @exchange_tasks.publish(JSON.generate(cmd: 'whoami'), :routing_key => 'tasks')
  @exchange_tasks.publish(JSON.generate(cmd: 'ls'), :routing_key => 'tasks')

  # master subscribes to results queue
  puts "Subscribe for results..."
  @queue_results.subscribe(block: true) do |delivery_info, metadata, payload|
    data = JSON.parse(payload)
    puts "Result has arrived: #{data}"
  end

end

########## WORKER ################
if options[:worker]
  puts "Start worker..."
  @exchange_results = @channel.default_exchange

  @queue_tasks.subscribe(block: true) do |delivery_info, metadata, payload|
    data = JSON.parse(payload)
    puts "Task has arrived: #{data}"
    # do the job and respond with result
    @exchange_results.publish(JSON.generate(res: "Result for #{data['cmd']}"), :routing_key => 'results')
  end
end
