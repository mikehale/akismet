require File.dirname(__FILE__) + '/spec_helper'

describe "Akismet" do
  include SpecHttp
  
  before do
    @akismet = Akismet.new('thekey', 'http://example.com')
  end
  
  it "should verify the key" do
    map Rack::URLMap.new("http://rest.akismet.com/" => lambda { |env| [200, {}, ["valid"]]})
    
    @akismet.verify_key.should == true
    request.post?.should == true
    request.env['HTTP_USER_AGENT'].should == "Akismet-rb/1.0 | Akismet/1.11"
    request.body.should include('http://example.com')
    response.status.should == 200
  end
  
  it "should detect spam" do
    map Rack::URLMap.new("http://thekey.rest.akismet.com/" => lambda { |env| [200, {}, ["true"]]})
    @akismet.spam?('').should == true
  end

  it "should detect ham" do
    map Rack::URLMap.new("http://thekey.rest.akismet.com/" => lambda { |env| [200, {}, ["false"]]})
    @akismet.ham?('').should == true
  end
end
