require File.expand_path 'magnet', File.dirname(__FILE__)

require 'em-http-request'
require 'json'

class Santa < Struct.new :url
  def initialize url
    super url

    @response_cbs = []
    @request = EventMachine::HttpRequest.new url
  end

  def response &block
    @response_cbs << block
  end

  def get
    http = @request.get
    http.callback do
      torrents = JSON.parse(http.response) \
        .map { |t| Magnet.new t['ih'], t['dn'], t['tr'] }
      @response_cbs.each { |a| a.call torrents } unless torrents.empty?
    end
  end

  def put magnets
    seeds = magnets.map &:to_hash
    @request.put body: seeds.to_json
  end
end
