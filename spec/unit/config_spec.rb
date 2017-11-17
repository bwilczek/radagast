require_relative '../../lib/radagast/config.rb'

RSpec.describe Radagast::Config do
  it 'sets default values for empty ARGV' do
    config = Radagast::Config.parse_argv
    expect(config.rabbit).to include('guest')
  end

  it 'sets rabbit value according to ARGV' do
    config = Radagast::Config.parse_argv '--rabbit rspec-rabbit'.split(' ')
    expect(config.rabbit).to eq 'rspec-rabbit'
  end

  it 'requires value for --rabbit switch' do
    expect do
      Radagast::Config.parse_argv ['--rabbit']
    end.to raise_error OptionParser::MissingArgument
  end
end
