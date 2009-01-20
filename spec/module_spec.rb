require File.dirname(__FILE__) + '/spec_helper.rb'

describe "User Module" do
  before(:each) do
    @manifest = UserManifest.new
  end

  it "should create a 'foo-user' aspect" do
    @manifest.send(:evaluate)
    @manifest.objects[Puppet::Type::User].keys.sort.should == ['foo']
  end

  it "should store created user in a way accessible to other aspects" do
    @manifest.moonshine_user.should == "foo"
  end

end
# 
# describe "Service Module" do
#   before(:each) do
#     @manifest = ServiceManifest.new
#   end
#   #TODO better testing to find actual objects in aspects
#   it "should create a 'foo-service' aspect" do
#     lambda { Puppet::DSL::Aspect["foo-service"] }.should_not raise_error
#   end
# end