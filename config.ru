require './presents'

set :user, 'sam@ifdown.net'
set :directory, 'foo'
set :rpc_port, 5555

raise "base dir must exists" unless Dir.exist? settings.directory

state_directory = File.join settings.directory, '.presents'
Dir.mkdir state_directory unless Dir.exist? state_directory
transmission_directory = File.join state_directory, 'transmission'

Torrents = Transmission.new settings.rpc_port, transmission_directory, settings.directory

PubSub = Santa.new settings.user, "http://localhost:8888/"

run Rack::Cascade.new [UIApp, PresentsApp]
