require 'uri'

module HttpIntercept
  def map(map)
    stub(TCPSocket).open(anything, numeric) { HttpShim.new(map) }
  end
end

module Rack
  class URLMap
    attr_reader :mapping
  end
  
  class RequestStringParser
    def self.env_key(key)
      "HTTP_" + key.split('-').join('_').upcase
    end
    
    def self.env(input)
      lines = input.split("\r\n")

      # find blank line which seperates the headers from the body
      index_of_blank = nil
      lines.each_with_index{|e,i|
        index_of_blank = i if e == ""
      }

      type, uri = lines.first.split(/\s+/)
      
      if index_of_blank
        headers = lines[1..index_of_blank]
        body = lines[(index_of_blank + 1)..-1].first
      else
        headers = lines[1..-1]
      end

      headers = headers.inject({}){|h,e|
        k,v = e.split(/:\s+/)
        h.merge! env_key(k) => v if k
        h
      }
      
      uri = URI(uri)
      env = headers.dup
      env["SERVER_NAME"] = uri.host
      env["SERVER_PORT"] = uri.port ? uri.port.to_s : "80"
      env["QUERY_STRING"] = uri.query.to_s
      env["PATH_INFO"] = (!uri.path || uri.path.empty?) ? "/" : uri.path
      env["SCRIPT_NAME"] = ""
      env["rack.url_scheme"] = uri.scheme || "http"
      env["rack.input"] = body
      env
    end
  end
  
  module Handler
    class StringIO
      def self.run(app, env={}, output=StringIO.new)
        # env.delete "HTTP_CONTENT_LENGTH"
        env["SCRIPT_NAME"] = ""  if env["SCRIPT_NAME"] == "/"
        env["QUERY_STRING"] ||= ""
        env["HTTP_VERSION"] ||= env["SERVER_PROTOCOL"]
        env["REQUEST_PATH"] ||= "/"

        status, headers, body = app.call(env)
        begin
          send_headers output, status, headers
          send_body output, body
          output.rewind
        ensure
          body.close  if body.respond_to? :close
        end
      end

      def self.send_headers(output, status, headers)
        output.print "HTTP/1.1 #{status} OK\r\n"
        headers.each { |k, vs|
          vs.each { |v|
            output.print "#{k}: #{v}\r\n"
          }
        }
        output.print "\r\n"
        output.flush
      end

      def self.send_body(output, body)
        body.each { |part|
          output.print part
          output.flush
        }
      end
    end
  end
end

class HttpShim < StringIO
  def initialize(map)
    @map = map
    super()
  end
  
  def write(string)
    raise "Already responded" if @response_io
    @written = '' unless @written
    @written << string
    string.size
  end
  
  alias :orig_sysread :sysread
  def sysread(size)
    unless @response_io
      @response_io = StringIO.new
      env = Rack::RequestStringParser.env(@written)
      
      @app = @map if !@map.respond_to? :mapping
      unless @app
        path = env["PATH_INFO"].to_s.squeeze("/")
        hHost, sName, sPort = env.values_at('HTTP_HOST','SERVER_NAME','SERVER_PORT')
        @map.mapping.each { |host, location, app|
          next unless (hHost == host || sName == host \
            || (host.nil? && (hHost == sName || hHost == sName+':'+sPort)))
          next unless location == path[0, location.size]
          next unless path[location.size] == nil || path[location.size] == ?/

          env["SCRIPT_NAME"] += location
          env["PATH_INFO"]    = path[location.size..-1]
          @app = app
        }
        raise "No application associated with #{env['rack.url_scheme']}://#{hHost}#{path}" unless @app
      end
      Rack::Handler::StringIO.run(@app, env, @response_io)
      self.string = @response_io.string
    end
    orig_sysread(size)
  end
end