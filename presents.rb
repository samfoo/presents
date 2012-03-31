require 'set'
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
    @seen = Set.new

    super
  end

  get '/presents' do
    # TODO: This should just all be done by JS instead of proxying.
    content_type 'application/json'

    magnets = @santa.receive

    magnets.select! { |m| !@seen.include? m.info_hash }
    magnets.each { |m| @seen << m.info_hash }

    magnets.map { |m| m.to_hash }.to_json
  end

  post '/:recipient/presents' do
    path = params['path']

    puts "Starting to seed #{path}"
    magnet = @torrents.seed path

    # TODO: This should just all be done by JS instead of proxying. The tricky
    # bit here is getting trasmission to seed the file before publishing it.
    @santa.publish params['recipient'], magnet

    content_type 'application/json'
    magnet.to_hash.to_json
  end
end
