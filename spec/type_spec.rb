require File.dirname(__FILE__) + '/spec_helper.rb'

describe "ShadowPuppet's type loading mechanism" do
  it "should create a new type helper methods when register_puppet_types is called" do
    Puppet::Type.newtype(:dummy_1){ }
    Puppet::Type.type(:dummy_1).provide(:generic){ }
    
    BlankManifest.new.respond_to?(:dummy_1).should == false
    ShadowPuppet::Manifest.register_puppet_types
    BlankManifest.new.respond_to?(:dummy_1).should == true
  end
end