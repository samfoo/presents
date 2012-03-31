require 'sinatra'
require 'coffee-script'

require './lib/santa'
require './lib/transmission'

set :username, 'dontcare'
set :directory, 'foo'
set :rpc_port, 5555

class UIApp < Sinatra::Application
  require 'haml'

  get '/scripts/:script.js' do
    coffee :"scripts/#{params["script"]}"
  end

  get '/' do
    haml :index
  end

  get '/config' do
    haml :config
  end
end

class PresentsApp < Sinatra::Application
  def initialize
    raise "base dir must exists" unless Dir.exist? settings.directory

    state_directory = File.join settings.directory, '.presents'
    Dir.mkdir state_directory unless Dir.exist? state_directory
    transmission_directory = File.join state_directory, 'transmission'

    @transmission = Transmission.new settings.rpc_port, transmission_directory, settings.directory
    @santa = Santa.new settings.username, settings.server
  end

  get '/:recipient/presents' do
    @santa.get do |magnets|
      magnets.each { |m| @transmission.add m }
    end
  end

  put '/:recipient/presents' do
    path = params['path']
    magnet = @transmission.seed path
    @santa.publish params['recipient'], magnet

    content_type 'application/json'
    magnet.to_has.to_json
  end
end
