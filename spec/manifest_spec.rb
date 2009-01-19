require File.dirname(__FILE__) + '/spec_helper.rb'

describe "A manifest" do

  describe "when blank" do

    before(:each) do
      @manifest = BlankManifest.new
    end

    it "does nothing" do
      @manifest.class.recipes.should == []
    end

    it "returns true when run" do
      @manifest.run.should be_true
    end

  end

  describe "in general" do

    before(:each) do
      @manifest = RequiresMetViaMethods.new
    end

    it "knows what it's supposed to" do
      @manifest.class.recipes.should == [:foo, :bar]
    end

    it "calls specified methods on #evaluate" do
      @manifest.should_receive(:foo)
      @manifest.should_receive(:bar)
      @manifest.evaluate
    end

    it "creates new resources on #evaluate" do
      @manifest.should_receive(:newresource).with(Puppet::Type::Exec, 'foo', :command => '/bin/true').exactly(1).times
      @manifest.should_receive(:newresource).with(Puppet::Type::Exec, 'bar', :command => '/bin/true').exactly(1).times
      @manifest.evaluate
    end

    it "calls creates new resources when evaluated" do
      @manifest.evaluate
      @manifest.objects.should_not == {}
    end

  end

end