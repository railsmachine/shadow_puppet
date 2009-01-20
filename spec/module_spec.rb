require File.dirname(__FILE__) + '/spec_helper.rb'

describe "User Module" do
  before(:each) do
    @manifest = UserManifest.new
    @manifest.send(:evaluate)
  end

  it "should create a 'foo' user" do
    @manifest.objects[Puppet::Type::User].keys.sort.should == ['foo']
  end

  it "should store created user in a way accessible to other aspects" do
    @manifest.moonshine_user.should == "foo"
  end

end

describe "Service Module" do
  before(:each) do
    @manifest = ServiceManifest.new
    @manifest.send(:evaluate)
  end

  it "should create a 'foo' service" do
    @manifest.objects[Puppet::Type::Service].keys.sort.should == ['foo']
  end

  it "should create dependent services" do
    @manifest.objects[Puppet::Type::Package].keys.sort.should == ['curl', 'wget']
  end
end

describe "Package Module" do

  before(:each) do
    @manifest = PackageManifest.new
    @manifest.send(:evaluate)
  end

  it "should create a appropriate packages" do
    @manifest.objects[Puppet::Type::Package].keys.sort.should == ['bar', 'foo']
  end

end

describe "Gem Module" do
  before(:each) do
    @manifest = GemManifest.new
    @manifest.send(:evaluate)
  end

  it "should create a appropriate packages" do
    @manifest.objects[Puppet::Type::Package].keys.sort.should == ['bar', 'foo', 'moonshine']
  end
end

describe "Ruby Module" do
  before(:each) do
    @manifest = RubyManifest.new
    @manifest.send(:evaluate)
  end

  it "should create a appropriate packages" do
    @manifest.objects[Puppet::Type::Exec].keys.should include('install-ruby')
  end
end