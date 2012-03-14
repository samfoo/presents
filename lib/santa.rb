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
    response = self.class.get(URI::join(@uri, "#{@user}/publications").to_s)
    torrents = JSON.parse(response.body) \
      .map { |t| Magnet.new t['ih'], t['dn'], t['tr'] }
    block.call torrents unless torrents.empty?
  end

  def publish recipient, magnets
    puts magnets.inspect
    self.class.put(URI::join(@uri, "#{@user}/publications/#{recipient}").to_s, body: magnets.map { |m| m.to_hash }.to_json)
  end
end
