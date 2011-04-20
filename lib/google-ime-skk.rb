require 'rubygems'
require 'socialskk'
require 'cgi'
require 'json'

class GoogleImeSkk < SocialSKK
  VERSION_STRING   = "GoogleImeSKK0.1 "

  def encode_to_utf8(text)
    if String.new.respond_to?(:encode)
      text.encode('utf-8', 'euc-jp')
    else
      require 'kconv'
      Kconv.toutf8(text)
    end
  end

  def encode_to_eucjp(text)
    if String.new.respond_to?(:encode)
      text.encode('euc-jp', 'utf-8')
    else
      require 'kconv'
      Kconv.toeuc(text)
    end
  end

  def social_ime_search(text)
    text = encode_to_utf8(text)
    text = text.sub(/[a-z]?$/) { |m| ',' + m }
    uri = URI.parse 'http://www.google.com/transliterate'
    http = Net::HTTP.new(uri.host, uri.port)
    http = Net::HTTP.new(uri.host, uri.port, @proxy.host, @proxy.port) if @proxy
    http.start do |h|
      res = h.get("/transliterate?langpair=ja-Hira%7Cja&text=" + URI.escape(text))
      obj = JSON.parse(res.body.to_s)
      encode_to_eucjp(obj[0][1].join('/'))
    end
  end
end
