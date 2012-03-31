require File.expand_path 'magnet', File.dirname(__FILE__)

require 'httparty'
require 'json'
require 'uri'

class Santa
  include HTTParty

  def initialize(user, uri)
    @user = user
    @uri = uri
  end

  def get &block
    torrents = receive
    block.call torrents unless torrents.empty?
  end

  def receive
    response = self.class.get(URI::join(@uri, "#{@user}/publications").to_s)
    JSON.parse(response.body) \
      .map { |t| Magnet.new t['ih'], t['dn'], t['tr'] }
  end

  def publish recipient, magnet
    url = URI::join(@uri, "#{@user}/publications/#{recipient}").to_s
    self.class.put(url, body: [magnet.to_hash].to_json)
  end
end
