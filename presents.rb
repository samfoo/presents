require 'sinatra'
require 'coffee-script'

require './lib/santa'
require './lib/transmission'

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
    @torrents = Torrents
  end

  get '/:recipient/presents' do
    @santa.get do |magnets|
      magnets.each { |m| @torrents.add m }
    end
  end

  put '/:recipient/presents' do
    path = params['path']
    magnet = @torrents.seed path
    @santa.publish params['recipient'], magnet

    content_type 'application/json'
    magnet.to_has.to_json
  end
end
