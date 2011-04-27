require File.dirname(__FILE__) + '/spec_helper.rb'

describe "ShadowPuppet's test helpers" do

  it "should be created when register_puppet_types_for_testing is called" do
    Puppet::Type.newtype(:dummy){ }
    Puppet::Type.type(:dummy).provide(:generic){ }
    
    BlankManifest.new.respond_to?(:dummies).should == false
    ShadowPuppet::Manifest.register_puppet_types_for_testing
    BlankManifest.new.respond_to?(:dummies).should == true
  end
  
  describe "when used in tests" do

    before do
      @manifest = TestHelpers.new
      @manifest.foo
    end
  
    it "should allow simple resource lookup" do
      @manifest.execs.keys.should == ['foo']
      @manifest.packages.keys.should == ['bar']
      @manifest.files.keys.should == ['/tmp/baz']
      @manifest.crons.keys.should == []
    end

    # making sure that properties such as, e.g the :onlyif condition of Exec[foo] 
    # can be accessed simply as manifest.execs['foo'].onlyif rather than via the 
    # param hash
    it "should allow referencing params directly" do
      @manifest.execs['foo'].command.should == 'true'
    end

  end

end
