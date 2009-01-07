require File.dirname(__FILE__) + '/spec_helper.rb'

describe "User Module" do
  before(:each) do
    @manifest = UserManifest.new
    @aspect = @manifest.role :debug do
      exec "whoami", :command => "/usr/bin/whoami > /tmp/whoami.txt"
    end
  end

  it "should create a 'foo-user' aspect" do
    lambda { Puppet::DSL::Aspect["foo-user"] }.should_not raise_error
  end

  it "should store created user" do
    @aspect.moonshine_user.should == "foo"
  end

end