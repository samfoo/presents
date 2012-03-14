require File.expand_path 'magnet', File.dirname(__FILE__)

require 'json'
require 'yaml'
require 'httparty'

class TransmissionRPCError < Exception; end

TorrentStatus = {
  0 => :stopped,
  1 => :check_wait,
  2 => :check,
  3 => :download_wait,
  4 => :download,
  5 => :seed_wait,
  6 => :seed,
}

class Transmission < Struct.new :port, :config_directory, :download_directory
  include HTTParty
  headers 'Content-Type' => 'application/json'

  def initialize port, config_directory, download_directory
    super port, config_directory, download_directory

    start

    settings = YAML.load_file File.join(config_directory, 'settings.json')
    path = settings['rpc-url']

    @uri = "http://localhost:#{port}#{path}rpc"
    @session_id = ''
  end

  def get &block
    opts = {fields: ['id', 'name', 'status', 'magnetLink']}
    rpc('torrent-get', opts) do |response|
      seeds = response['torrents'].select do |t|
        TorrentStatus[t['status']] == :seed
      end.map { |t| Magnet.parse t['magnetLink'] }

      block.call seeds unless seeds.empty?
    end
  end

  def add magnet
    rpc('torrent-get', ids: [magnet.info_hash], fields: ['trackers']) do |response|
      if !already_downloading? response
        start_downloading magnet
      else
        add_new_trackers magnet, response
      end
    end
  end

  def rpc method, args, &block
    request = -> { self.class.post @uri, body: {method: method, arguments: args}.to_json }

    response = request.call

    parsed_response = if response.code == 409
                        self.class.headers 'X-Transmission-Session-Id' => response.headers['x-transmission-session-id']
                        request.call.parsed_response
                      else
                        response.parsed_response
                      end

    if parsed_response['result'] == 'success'
      block.call parsed_response['arguments'] if block_given?
    else
      raise TransmissionRPCError.new parsed_response['result']
    end
  end

  private

  def add_new_trackers magnet, ti
    trackers = ti['torrents'].map do |torrent|
      torrent['trackers'].map { |tr| tr['announce'] }
    end.flatten

    new_trackers = magnet.trackers - trackers
    unless new_trackers.empty?
      rpc('torrent-set', ids: [magnet.info_hash], trackerAdd: new_trackers) do
        puts "Fixed trackers on #{magnet.info_hash}"
      end
    end
  end

  def already_downloading? ti
    !ti['torrents'].empty?
  end

  def start_downloading magnet
    rpc('torrent-add', filename: magnet.to_s) do
      puts "Downloading #{magnet.display_name} ..."
    end
  end

  def start
    incomplete_directory = File.join config_directory, 'incomplete'

    [config_directory, incomplete_directory].each do |d|
      Dir.mkdir d unless Dir.exists? d
    end

    # TODO: Check the PID to prevent duplicate processes.
    transmission_pid = fork do
      opts = [
        "--config-dir #{config_directory}",
        "--incomplete-dir #{incomplete_directory}",
        "--download-dir #{download_directory}",
        "--port #{port}",
        "--peerport #{port + 1}",

        '--dht',
        '--encryption-preferred',
        '--lpd',
        '--portmap',
        '--utp',

        '--foreground',
      ]

      exec 'transmission-daemon ' + opts.join(' ')
    end
    Signal.trap('EXIT') do
      Process.kill 'TERM', transmission_pid
      Process.wait
    end

    # TODO: Properly wait for settings.json
    sleep 1
  end
end
