require File.expand_path 'magnet', File.dirname(__FILE__)

require 'httparty'
require 'json'

class Santa
  include HTTParty

  def initialize(uri)
    @uri = uri
  end

  def get &block
    response = self.class.get(@uri)
    torrents = JSON.parse(response.body) \
      .map { |t| Magnet.new t['ih'], t['dn'], t['tr'] }
    block.call torrents unless torrents.empty?
  end

  def publish magnets
    self.class.put(@uri, body: magnets.to_json)
  end
end
