require 'sinatra'
require 'json'
require 'sequel'
require 'logger'
require 'base64'
require 'bencode'
require 'cgi'

DB = Sequel.sqlite '', :loggers => [Logger.new($stdout)]
DB.sql_log_level = :debug

DB.create_table :clients do
  primary_key :id
  String :client_id, :unique => true
  DateTime :last_updated_at
end

DB.create_table :files do
  primary_key :id
  String :name
  Int :length
  Int :piece_length
  String :pieces
  DateTime :published_at
  Int :client_id
end

def files
  DB[:files]
end

def clients
  DB[:clients]
end

def magnetize(file, tracker="http://localhost:8888/announce")
  info = {
    "name" => file[:name],
    "length" => file[:length],
    "piece length" => file[:piece_length],
    "pieces" => Base64::decode64(file[:pieces])
  }

  info_hash = Digest::SHA1.hexdigest info.bencode

  "magnet:?xt=urn:btih:#{info_hash}&dn=#{CGI.escape(file[:name])}&tr=#{CGI.escape(tracker)}"
end

get '/files' do
  client = params["client_id"].to_i
  puts "serving to #{client}"

  client_already_exists = clients.where(:client_id => client).first
  puts client_already_exists.inspect
  if !client_already_exists
    puts "#{client} doesn't exist, so I'll create him"
    clients.insert(:client_id => client, :last_updated_at => Time.now)
  end

  last_updated_at = clients.where(:client_id => client).first[:last_updated_at]

  puts "finding stale files for #{client}"
  publications = files.filter { (published_at > last_updated_at) & ~{:client_id => client} }

  puts "updating #{client}'s last checkin time"
  clients.where(:client_id => client).update(:last_updated_at => Time.now)

  publications.map { |p| magnetize(p) }.to_json
end

post '/files' do
  data = JSON.parse(request.body.read)

  files.insert(
    name: data["name"],
    length: data["length"].to_i,
    piece_length: data["piece length"].to_i,
    pieces: data["pieces"],
    published_at: Time.now,
    client_id: params["client_id"]
  )

  {"message" => "Santa thanks you for your present."}.to_json
end
