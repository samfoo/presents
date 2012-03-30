require 'sinatra'
require 'haml'
require 'coffee-script'

get '/scripts/:script.js' do
  coffee :"scripts/#{params["script"]}"
end

get '/' do
  haml :index
end

get '/config' do
  haml :config
end
