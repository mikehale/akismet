require File.dirname(__FILE__) + '/spec_helper'

describe "Akismet with valid key and url" do
  before do
    @io = HttpResponse.ok({}, "valid")
    mock(TCPSocket).open('rest.akismet.com', 80) { @io }
    @akismet = Akismet.new('thekey', 'theblog')
  end

  it "should send the proper user agent" do
    @akismet.verify_key # only needed to make the request
    @io.written.should include(Akismet::USER_AGENT)
  end

  it "should verify the key" do
    @akismet.verify_key.should == true
  end

  it "should check a comment"
  it "should submit spam"
  it "should submit ham"
end

describe "Akismet with invalid key and url" do
  before do
    @io = HttpResponse.ok({"x-akismet-debug-help"=>["debug help"]}, "invalid")
    mock(TCPSocket).open('rest.akismet.com', 80) { @io }
    @akismet = Akismet.new('thekey', 'theblog')
  end

  it "should not verify the key" do
    lambda {@akismet.verify_key}.should raise_error(Akismet::VerifyException)
  end

  # don't know how to test this yet
  it "should raise an exception with the content of the x-akismet-debug-help header"
end
