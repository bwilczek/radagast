require 'bunny'
require 'json'
require 'optparse'
require 'open3'

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
    @published_cnt = 0
    @processed_cnt = 0
    @all_results = []

    # master subscribes to results queue
    t = Thread.new do
      puts "Subscribe for results..."
      @queue_results.subscribe(block: true) do |delivery_info, metadata, payload|
        @processed_cnt += 1
        data = JSON.parse(payload)
        @all_results << data
        puts "Result #{@processed_cnt}/#{@published_cnt} has arrived: #{data}"
        if @processed_cnt == @published_cnt
          puts ""
          puts "Aggregate the results (size: #{@all_results.length})"
          puts " > with non-zero exit code: #{@all_results.count {|i| i['exitstatus'] != 0}}"
          puts "... and exit"
          @rabbit.close
        end
      end
    end

    # publish some example tasks
    puts "Publish some tasks..."
    @exchange_tasks.publish(JSON.generate(cmd: 'pwd'), :routing_key => 'tasks')
    @published_cnt += 1
    @exchange_tasks.publish(JSON.generate(cmd: 'id'), :routing_key => 'tasks')
    @published_cnt += 1
    @exchange_tasks.publish(JSON.generate(cmd: 'cat /etc/shadow'), :routing_key => 'tasks')
    @published_cnt += 1
    @exchange_tasks.publish(JSON.generate(cmd: 'cat /etc/passwd | grep bwilczek'), :routing_key => 'tasks')
    @published_cnt += 1
    @exchange_tasks.publish(JSON.generate(cmd: 'whoami'), :routing_key => 'tasks')
    @published_cnt += 1
    @exchange_tasks.publish(JSON.generate(cmd: 'ls /no/such/path'), :routing_key => 'tasks')
    @published_cnt += 1
    @exchange_tasks.publish(JSON.generate(cmd: 'ruby -v'), :routing_key => 'tasks')
    @published_cnt += 1
    @exchange_tasks.publish(JSON.generate(cmd: 'bundle list'), :routing_key => 'tasks')
    @published_cnt += 1
    @exchange_tasks.publish(JSON.generate(cmd: 'ls -la'), :routing_key => 'tasks')
    @published_cnt += 1

    t.join
  end

  ########## WORKER ################
  if options[:worker]
    worker_id = rand(100..999)
    puts "Start worker #{worker_id}..."
    @exchange_results = @channel.default_exchange

    @queue_tasks.subscribe(block: true) do |delivery_info, metadata, payload|
      data = JSON.parse(payload)
      puts "Task has arrived: #{data}"
      # do the job and respond with result
      sleep rand(1..3)
      stdout, stderr, status = Open3.capture3(data['cmd'])
      response = {
        cmd: data['cmd'],
        meta: data['meta'],
        stdout: stdout,
        stderr: stderr,
        exitstatus: status.exitstatus
      }
      @exchange_results.publish(JSON.generate(response), :routing_key => 'results')
    end
  end
rescue SystemExit, Interrupt
  puts 'Closing RabbitMQ connection...'
  @rabbit.close
end
