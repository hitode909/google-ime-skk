require "thread"
require 'socket'
require 'uri'
require 'net/http'
require 'timeout'
require 'yaml'

# http://coderepos.org/share/browser/lang/ruby/misc/socialskk/socialskk.rb

Net::HTTP.version_1_2

class SocialSKK
  VERSION_STRING   = "SocialSKK0.2 "

  CLIENT_END       = ?0
  CLIENT_REQUEST   = ?1
  CLIENT_VERSION   = ?2
  CLIENT_HOST      = ?3
  SERVER_ERROR     = ?0
  SERVER_FOUND     = ?1
  SERVER_NOT_FOUND = ?4

  BUFSIZE    = 512
  TIMEOUT    = 10

  def initialize(host, port, proxy, cache_time, cache=nil)
    @host  = host
    @port  = port
    @proxy = proxy
    @cache = cache || {}
    @cache_time = cache_time
    @ts = TCPServer.open(@host, @port)
    puts "server is on #{@ts.addr[1..-1].join(":")}"
    puts "proxy is #{@proxy.to_s}" if @proxy
    puts "cache keep time #{@cache_time}sec"
  end

  def mainloop
    loop do
      Thread.start(@ts.accept) do |s|
        while cmdbuf = s.sysread(BUFSIZE)
          case cmdbuf[0]
          when CLIENT_END
            break
          when CLIENT_REQUEST
            cmdend = cmdbuf.index(?\ ) || cmdbuf.index(?\n)
            kana = cmdbuf[1 .. (cmdend - 1)]
            ret = ''
            begin
              if kanji = search(kana)
                ret.concat(SERVER_FOUND)
                ret.concat('/')
                ret.concat(kanji)
              else
                ret.concat(SERVER_NOT_FOUND)
                ret.concat(cmdbuf[1 .. -1])
              end
              ret.concat("\n")
            rescue Exception
              ret.concat(SERVER_ERROR)
              ret.concat($!)
            end
            s.write(ret)
          when CLIENT_VERSION
            s.write(VERSION_STRING)
          when CLIENT_HOST
            ret = host(s)
            s.write(ret)
          end
        end
        s.close
      end
    end
  end

  private
  def host(sock = nil)
    if sock.nil?
      hostname = Socket.gethostname
      ipaddr = TCPSocket.getaddress(hostname)
    else
      hostname, ipaddr = sock.addr[2], sock.addr[3]
    end

    hostname + ':' + ipaddr + ': '
  end

  def search(kana)
    if @cache[kana] and Time.now < (@cache[kana][:ctime] + @cache_time)
      @cache[kana][:kanji]
    else
      kanji = social_ime_search(kana)
      @cache[kana] = {
        :kanji => kanji,
        :ctime => Time.now
      }
      kanji
    end
  end

  def social_ime_search(kana)
    size = kana.size / 2
    kanji = '/'
    begin
      timeout(TIMEOUT) do
        http = Net::HTTP.new('www.social-ime.com', 80)
        http = Net::HTTP.new('www.social-ime.com', 80, @proxy.host, @proxy.port) if @proxy
        http.start do |h|
          res = h.get("/api/?string=#{URI.escape(kana)}&resize[0]=+#{size}")
          kanji += res.body.to_s.split("\n").join('/').gsub(/\t/, '/')
        end
      end
    rescue
      kanji = nil
    end
    kanji
  end
end
