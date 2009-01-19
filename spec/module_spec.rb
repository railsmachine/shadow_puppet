require File.dirname(__FILE__) + '/spec_helper.rb'

# describe "User Module" do
#   before(:each) do
#     @manifest = UserManifest.new
#     @aspect = @manifest.role :debug do
#       exec "whoami", :command => "/usr/bin/whoami > /tmp/whoami.txt"
#     end
#   end
# 
#   it "should create a 'foo-user' aspect" do
#     lambda { Puppet::DSL::Aspect["foo-user"] }.should_not raise_error
#   end
# 
#   it "should store created user in a way accessible to other aspects" do
#     @aspect.moonshine_user.should == "foo"
#   end
# 
# end
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