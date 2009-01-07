require File.dirname(__FILE__) + '/spec_helper.rb'

describe "User Module" do
  before(:each) do
    @manifest = UserManifest.new
  end

  it "should create a 'foo-user' aspect" do
    lambda { Puppet::DSL::Aspect["foo-user"] }.should_not raise_error
  end
end