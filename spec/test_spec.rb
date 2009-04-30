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
      @manifest.execs.should == @manifest.puppet_resources[Puppet::Type::Exec]
      @manifest.packages.should == @manifest.puppet_resources[Puppet::Type::Package]
      @manifest.files.should == @manifest.puppet_resources[Puppet::Type::File]
    end

    # making sure that properties such as, e.g the :onlyif condition of Exec[foo] 
    # can be accessed simply as manifest.execs['foo'].onlyif rather than via the 
    # param hash
    it "should allow referencing params directly" do
      %w(execs files packages).each do |type|
        @manifest.send(type.to_sym).each do |name,resource|
          resource.params.keys.each do |param|
            resource.send(param.to_sym).should == resource.params[param.to_sym].value
          end
        end
      end
    end

  end

end