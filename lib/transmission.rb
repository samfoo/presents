require File.expand_path 'magnet', File.dirname(__FILE__)

require 'json'
require 'yaml'

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
  def initialize port, config_directory, download_directory
    super port, config_directory, download_directory

    start

    settings = YAML.load_file File.join(config_directory, 'settings.json')
    path = settings['rpc-url']

    @rpc = EventMachine::HttpRequest.new "http://localhost:#{port}#{path}rpc"
    @session_id = ''
    @response_cbs = []
  end

  def response &block
    @response_cbs << block
  end

  def get
    opts = {fields: ['id', 'name', 'status', 'magnetLink']}
    rpc('torrent-get', opts) do |response|
      seeds = response['torrents'].select do |t|
        TorrentStatus[t['status']] == :seed
      end.map { |t| Magnet.parse t['magnetLink'] }

      @response_cbs.each { |s| s.call seeds } unless seeds.empty?
    end
  end

  def add magnet
    rpc('torrent-get', ids: [magnet.info_hash], fields: ['trackers']) do |response|
      if response['torrents'].empty?
        rpc('torrent-add', filename: magnet.to_s) do
          puts "Downloading #{magnet.display_name} ..."
        end
      else
        trackers = response['torrents'].map do |torrent|
          torrent['trackers'].map { |tr| tr['announce'] }
        end.flatten

        new_trackers = magnet.trackers - trackers
        unless new_trackers.empty?
          rpc('torrent-set', ids: [magnet.info_hash], trackerAdd: new_trackers) do
            puts "Fixed trackers on #{magnet.info_hash}"
          end
        end
      end
    end
  end

  def rpc method, args, &block
    request = @rpc.post \
      body: {method: method, arguments: args}.to_json,
      head: {'X-Transmission-Session-Id' => @session_id}
    request.callback do
      if request.response_header.status == 409
        @session_id = request.response_header['X_TRANSMISSION_SESSION_ID']
        rpc method, args, &block
      else
        parsed_response = JSON.parse request.response

        if parsed_response['result'] == 'success'
          block.call parsed_response['arguments'] if block_given?
        else
          # TODO: This exception stops the app, but the call stack is lost.
          # Why?!
          raise TransmissionRPCError.new parsed_response['result']
        end
      end
    end
  end

  private

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
