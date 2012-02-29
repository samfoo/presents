require 'httparty'
require 'json'
require 'yaml'
require 'base64'
require 'bencode'

class TransmissionRPCError < Exception
end

class BadTorrentSource < Exception
end

TorrentStatus = {
  0 => :stopped,
  1 => :check_wait,
  2 => :check,
  3 => :download_wait,
  4 => :download,
  5 => :seed_wait,
  6 => :seed,
}

class Transmission
  include HTTParty

  headers 'Content-Type' => 'application/json'

  def initialize config_path
    settings = YAML.load_file File.join(config_path, 'settings.json')

    @path = settings['rpc-url']
    @port = settings['rpc-port']
  end

  def download_dir
    response = rpc 'session-get', {}
    response['download-dir']
  end

  def download_dir= directory
    rpc 'session-set', 'download-dir' => directory
  end

  def add name
    if name.kind_of? Hash
      rpc 'torrent-add', metainfo: Base64::encode64(name.bencode)
    elsif name.start_with?('magnet:') || File.readable?(name)
      rpc 'torrent-add', filename: name
    else
      raise BadTorrentSource.new name
    end
  end

  def move ids, location
    rpc 'torrent-set-location', location: location, move: true
  end

  def status ids=[]
    opts = {fields: ['id', 'name', 'status']}
    opts[ids] = ids unless ids.empty?

    response = rpc 'torrent-get', opts
    response['torrents'].each do |t|
      t['status'] = TorrentStatus[t['status']]
    end
  end

  def rpc method, args
    request = -> { self.class.post "http://localhost:#{@port}#{@path}rpc", body: {method: method, arguments: args}.to_json }

    response = request.call

    parsed_response = if response.code == 409
                        self.class.headers 'X-Transmission-Session-Id' => response.headers['x-transmission-session-id']
                        request.call.parsed_response
                      else
                        response.parsed_response
                      end

    raise TransmissionRPCError.new(parsed_response['result']) unless parsed_response['result'] == 'success'
    parsed_response['arguments']
  end
end
