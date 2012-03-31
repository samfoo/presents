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
    @santa = PubSub

    super
  end

  get '/presents' do
    # TODO: This should just all be done by JS instead of proxying.
    content_type 'application/json'
    @santa.receive.to_json
  end

  put '/:recipient/presents' do
    path = params['path']
    magnet = @torrents.seed path
    @santa.publish params['recipient'], magnet

    content_type 'application/json'
    magnet.to_has.to_json
  end
end
