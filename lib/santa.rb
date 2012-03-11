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
    response = self.class.get(URI::join(@uri, "#{@user}/publications"))
    torrents = JSON.parse(response.body) \
      .map { |t| Magnet.new t['ih'], t['dn'], t['tr'] }
    block.call torrents unless torrents.empty?
  end

  def publish recipient, magnets
    self.class.put(URI::join(@uri, "#{@user}/publications/#{recipient}", body: magnets.to_json)
  end
end
