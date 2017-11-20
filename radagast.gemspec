$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name         = 'radagast'
  s.version      = '0.0.1'
  s.summary      = 'Radagast - a framework for distributed command execution'
  s.description  = 'Use docker swarm and rabbitmq to distribute tasks. \
    Designed for faster test execution.'
  s.author       = 'Bartek Wilczek'
  s.email        = 'bwilczek@gmail.com'
  s.files        = Dir['lib/**/*.rb'] + Dir['bin/*']
  s.require_path = 'lib'
  s.homepage     = 'https://github.com/bwilczek/radagast'
  s.license      = 'MIT'
  s.executables << 'radagast'
  s.required_ruby_version = '~> 2.0'
  s.add_runtime_dependency 'bunny', '~> 2.6'
  s.add_development_dependency 'rspec', '~> 3.7'
end
