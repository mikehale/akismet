require 'spec'
require 'rr'
require 'rack/urlmap'
require File.dirname(__FILE__) + '/spec_http'
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

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'akismet'

Spec::Runner.configure do |config|
  config.mock_with :rr
end