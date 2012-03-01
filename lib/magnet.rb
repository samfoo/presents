require 'cgi'

class Magnet < Struct.new :info_hash, :display_name
  def self.parse magnet_uri
    uri = URI::parse magnet_uri
    raise ArgumentError unless uri.scheme == 'magnet'

    qs = CGI::parse uri.opaque[1..-1]
    xt, dn = qs['xt'].first, qs['dn'].first

    /urn:btih:(?<ih>[0-9a-fA-F]{40})/ =~ xt
    raise ArgumentError unless ih && dn

    Magnet.new ih.to_s, dn.to_s
  end

  def to_s
    "magnet:?xt=urn:btih:#{CGI.escape info_hash}&dn=#{CGI.escape display_name}"
  end

  def to_hash
    {ih: info_hash, dn: display_name}
  end
end
