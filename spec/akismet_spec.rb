require File.dirname(__FILE__) + '/spec_helper'

describe "Akismet" do
  include HttpIntercept
  
  it "should verify the key" do
    map Rack::URLMap.new("http://rest.akismet.com/" => lambda { |env| [200, {}, ["valid"]]})
    @akismet = Akismet.new('thekey', 'http://example.com')
    @akismet.verify_key.should == true
  end
  
  it "should detect spam" do
    map Rack::URLMap.new("http://thekey.rest.akismet.com/" => lambda { |env| [200, {}, ["true"]]})
    @akismet = Akismet.new('thekey', 'http://example.com')
    @akismet.spam?('').should == true
  end

  it "should detect ham" do
    map Rack::URLMap.new("http://thekey.rest.akismet.com/" => lambda { |env| [200, {}, ["false"]]})
    @akismet = Akismet.new('thekey', 'http://example.com')
    @akismet.ham?('').should == true
  end
end
