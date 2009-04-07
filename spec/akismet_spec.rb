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
    map Rack::URLMap.new("http://thekey.rest.akismet.com/" => app)
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

  it "should detect ham" do
    @akismet.ham?(params.update(:comment_content => "not spam")).should == true
  end
end
