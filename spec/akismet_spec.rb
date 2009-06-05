require File.dirname(__FILE__) + '/spec_helper'

describe "Akismet" do
  include SpecHttp
  
  def params
    {
      :user_ip => "1.2.3.4",
      :referrer => "http://othersite.com",
      :permalink => "http://example.com/post",
      :comment_type => "comment",
      :comment_author => "joe smith",
      :comment_author_email => "joe@smith.com",
      :comment_author_url => "blog.smith.com"
    }
  end
  
  before do
    @akismet = Akismet.new('thekey', 'http://example.com')
    app = lambda do |env|
      spam = env["rack.input"].include?('viagra')
      [200, {}, [spam ? "true" : "false"]]
    end
    map Rack::URLMap.new("http://thekey.rest.akismet.com/1.1/comment-check" => app)
  end
  
  it "should verify the key" do
    map Rack::URLMap.new("http://rest.akismet.com/" => lambda { |env| [200, {}, ["valid"]]})
    
    @akismet.verify?.should == true
    request.post?.should == true
    request.env['HTTP_USER_AGENT'].should match(/Akismet-rb\/\d\.\d\.\d/)
    request.body.should include('http://example.com')
    response.status.should == 200
  end
  
  it "should only verify the key once per instance" do
    map Rack::URLMap.new("http://rest.akismet.com/" => lambda { |env| [200, {}, ["valid"]]})
    mock.proxy(Net::HTTP).start(anything, numeric).times(1)
    
    @akismet.verify?.should == true
    @akismet.verify?.should == true
  end
  
  it "should not verify an invalid key" do
    map Rack::URLMap.new("http://rest.akismet.com/" => lambda { |env| [200, {'x-akismet-debug-help' => 'sorry!'}, ["invalid"]]})    
    lambda {@akismet.verify?}.should raise_error(Akismet::VerifyError)
    response['x-akismet-debug-help'].should == 'sorry!'
  end
  
  it "should detect spam" do
    @akismet.spam?(params.update(:comment_content => "viagra-test-123")).should == true
    request.env.has_key?('HTTP_USER_AGENT').should == true
    request.body.should include("blog=http://example.com")
    request.body.should include("user_ip=1.2.3.4")
    request.body.should include("referrer=http://othersite.com")
    request.body.should include("permalink=http://example.com/post")
    request.body.should include("comment_type=comment")
    request.body.should include("comment_author=joe%20smith")
    request.body.should include("comment_author_email=joe@smith.com")
    request.body.should include("comment_author_url=blog.smith.com")
    request.body.should include("comment_content=viagra-test-123")
  end
  
  it "should handle nil values" do
    lambda {@akismet.spam?(params.update(:referrer => nil))}.should_not raise_error
  end

  it "should detect ham" do
    @akismet.ham?(params.update(:comment_content => "not spam")).should == true
  end
  
  it "should submit spam" do
    map Rack::URLMap.new("http://thekey.rest.akismet.com/1.1/submit-spam" => lambda { |env| [200, {}, "true"]})
    @akismet.submit_spam(params.update(:comment_content => "this-is-spam"))
    request.script_name.should == "/1.1/submit-spam"
    
    request.env.has_key?('HTTP_USER_AGENT').should == true
    request.body.should include("blog=http://example.com")
    request.body.should include("user_ip=1.2.3.4")
    request.body.should include("referrer=http://othersite.com")
    request.body.should include("permalink=http://example.com/post")
    request.body.should include("comment_type=comment")
    request.body.should include("comment_author=joe%20smith")
    request.body.should include("comment_author_email=joe@smith.com")
    request.body.should include("comment_author_url=blog.smith.com")
    request.body.should include("comment_content=this-is-spam")
  end
  
  it "should submit ham" do
    map Rack::URLMap.new("http://thekey.rest.akismet.com/1.1/submit-ham" => lambda { |env| [200, {}, "true"]})
    @akismet.submit_ham(params.update(:comment_content => "this-is-ham"))
    request.script_name.should == "/1.1/submit-ham"
  end
  
  describe "verify?" do
    it "should handle a SocketError" do
      map Rack::URLMap.new("http://rest.akismet.com/" => lambda { |env| raise SocketError })
      mock.proxy(Net::HTTP).start(anything, numeric)
      lambda {@akismet.verify?}.should raise_error(Akismet::VerifyError)
    end
  end

  describe "call_akismet" do
    it "should handle a SocketError" do
      map Rack::URLMap.new("http://thekey.rest.akismet.com/1.1/comment-check" => lambda { |env| raise SocketError })
      lambda { @akismet.ham?(params.update(:comment_content => "not spam"))}.should raise_error(Akismet::CheckError)
    end
  end
end
