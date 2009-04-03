require 'spec'
require 'rr'
require 'ruby-debug'

class MethodSpy
  def initialize(delegate, &block)
    @delegate = delegate
    @filter = block
  end

  def method_missing(symbol, *args, &block)
    result = @delegate.send(symbol, *args, &block)
    p [symbol, args, result, block]
    result
  end
end

class HttpResponse
  def self.ok(headers, body)
    response = [%(HTTP/1.1 200 OK)]
    headers.each{|k,vs|
      if vs.is_a?(Array)
        response << vs.map{|v| "#{k.to_s}: #{v.to_s}" }
      else
        response << "#{k.to_s}: #{vs.to_s}"
      end
    }
    response << ''
    response << %(#{body})
    response = response.join("\r\n")

    io = StringIO.new(response)
    def io.written
      @written
    end

    def io.write(content)
      @written = '' unless @written
      @written << content
      0
    end

    io
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'akismet'

Spec::Runner.configure do |config|
  config.mock_with :rr
end