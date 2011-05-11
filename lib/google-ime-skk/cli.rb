require 'google-ime-skk'
require 'optparse'
require 'ostruct'

module GoogleImeSkk::CLI

  def self.time_parse(str)
    n, u = str.scan(/(\d+)([dhms]?)/)[0]
    n = n.to_i
    case (u)
    when "d"
      n *= 24 * 60 * 60
    when "h"
      n *= 60 * 60
    when "m"
      n *= 60
    end
    n
  end

  def self.execute
    opts = OpenStruct.new({
        :port   => 55100,
        :host   => '0.0.0.0',
        :proxy  => nil,
        :cache_time => 3600,
      })

    OptionParser.new do |parser|
      parser.instance_eval do
        self.banner  = "Usage: #{$0} [opts]"

        separator ''
        separator 'Options:'
        on('-p', '--port 55100', 'Listen port number') do |port|
          opts.port = port
        end
        on('-h', '--host "0.0.0.0"', 'Listen hostname') do |host|
          opts.host = host
        end
        on('-x', '--proxy "http://proxy.example.com:8080"', 'HTTP Proxy server') do |proxy|
          opts.proxy = URI.parse(proxy)
        end
        on('-c', '--cache-time 1h', 'Cache keep time') do |ct|
          opts.cache_time = GoogleImeSkk::CLI.time_parse(ct)
        end

        parse!(ARGV)
      end
    end

    ime = GoogleImeSkk.new(opts.host, opts.port, opts.proxy, opts.cache_time)
    ime.mainloop
  end
end
