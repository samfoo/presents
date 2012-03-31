require './presents'

require 'sinatra/config_file'

set :environments, %w{sam scott someone}
set :root, Dir.getwd
config_file 'config.yml'

raise "base dir must exists" unless Dir.exist? settings.directory

state_directory = File.join settings.directory, '.presents'
Dir.mkdir state_directory unless Dir.exist? state_directory
transmission_directory = File.join state_directory, 'transmission'

Torrents = Transmission.new settings.rpc_port, transmission_directory, settings.directory

PubSub = Santa.new settings.user, "http://localhost:8888/"

run Rack::Cascade.new [UIApp, PresentsApp]
