require 'cgi'

class Magnet < Struct.new :info_hash, :display_name, :trackers
  def self.parse magnet_uri
    uri = URI::parse magnet_uri
    raise ArgumentError unless uri.scheme == 'magnet'

    qs = CGI::parse uri.opaque[1..-1]
    xt, dn, tr = qs['xt'].first, qs['dn'].first, qs['tr']

    /urn:btih:(?<ih>[0-9a-fA-F]{40})/ =~ xt
    raise ArgumentError unless ih && dn

    Magnet.new ih.to_s, dn.to_s, tr
  end

  def to_s
    "magnet:?" + [
      "xt=urn:btih:#{CGI.escape info_hash}",
      "dn=#{CGI.escape display_name}",
      *trackers.map { |s| 'tr=' + CGI.escape(s) },
    ].join('&')
  end

  def to_hash
    {ih: info_hash, dn: display_name, tr: trackers}
  end
end
