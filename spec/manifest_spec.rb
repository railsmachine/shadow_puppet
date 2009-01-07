require File.dirname(__FILE__) + '/spec_helper.rb'

describe "A manifest" do

  before(:each) do
    @manifest = BlankManifest.new
  end

  describe "when blank" do

    it "should have no instance level roles defined" do
      @manifest.instance_roles.should have(0).items
    end

    it "should have no class level roles defined" do
      BlankManifest.class_roles.should have(0).items
    end

  end

  describe "with class level roles" do

    before(:each) do
      @manifest = ClassLevelRole.new
    end

    it "should have no instance level roles defined" do
      @manifest.instance_roles.should have(0).items
    end

    it "should have appropriate class level roles defined" do
      ClassLevelRole.class_roles.should have(1).items
    end

    it "should create puppet aspects from the class roles" do
      lambda { Puppet::DSL::Aspect[:debug] }.should_not raise_error
    end

  end

  describe "with instance level roles" do

    before(:each) do
      @manifest = BlankManifest.new
      @manifest.role :debug do
        exec "whoami", :command => "/usr/bin/whoami > /tmp/whoami.txt"
      end
    end

    it "should have no class level roles defined" do
      BlankManifest.class_roles.should have(0).items
    end

    it "should have appropriate instance level roles defined" do
      @manifest.instance_roles.should have(1).items
    end

    it "should create puppet aspects from the instance roles" do
      lambda { Puppet::DSL::Aspect[:debug] }.should_not raise_error
    end

  end

end