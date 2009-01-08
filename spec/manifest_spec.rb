require File.dirname(__FILE__) + '/spec_helper.rb'

describe "A manifest" do

  before(:each) do
    @manifest = BlankManifest.new
  end

  describe "when blank" do

    it "should have no instance level aspects defined" do
      @manifest.aspects.should have(0).items
    end

    it "should have no class level aspects defined" do
      BlankManifest.aspects.should have(0).items
    end

  end

  describe "with class level aspects" do

    before(:each) do
      @manifest = ClassLevelRole.new
    end

    it "should have appropriate class level aspects defined" do
      ClassLevelRole.aspects.should have(1).items
    end

    it "should be available at the instance level" do
      @manifest.aspects.should have(1).items
    end

    it "should create puppet aspects from the class aspects" do
      lambda { Puppet::DSL::Aspect[:debug] }.should_not raise_error
    end

    describe "declared multiple times" do
      before(:each) do
        @manifest2 = ClassLevelRole.new
      end

      it "should be defined as class level aspects" do
        ClassLevelRole.aspects.should have(1).items
      end

      it "should create puppet aspects from the class aspects" do
        lambda { Puppet::DSL::Aspect[:debug] }.should_not raise_error
      end

      describe "mixed with instance level aspects" do
        before(:each) do
          @manifest2.role :test do
            exec "echo", :command => "/bin/echo 'foo' > /tmp.foo.txt"
          end
        end

        it "should have 2 aspects on the instance" do
          @manifest2.aspects.should have(2).items
        end

        it "should have only one class level aspect defined" do
          ClassLevelRole.aspects.should have(1).items
        end

        it "should create puppet aspects from the instance level aspects" do
          lambda { Puppet::DSL::Aspect[:test] }.should_not raise_error
        end

      end

    end

  end

  describe "with instance level aspects" do

    before(:each) do
      @manifest = BlankManifest.new
      @manifest.role :debug do
        exec "whoami", :command => "/usr/bin/whoami > /tmp/whoami.txt"
      end
    end

    it "should have no class level aspects defined" do
      BlankManifest.aspects.should have(0).items
    end

    it "should have appropriate instance level aspects defined" do
      @manifest.aspects.should have(1).items
    end

    it "should create puppet aspects from the instance aspects" do
      lambda { Puppet::DSL::Aspect[:debug] }.should_not raise_error
    end

  end

  describe "dependencies" do

    before(:each) do
      @manifest = BlankManifest.new
      @aspect = @manifest.role :debug do
        exec "whoami", :command => "/usr/bin/whoami > /tmp/whoami.txt"
      end
    end

    it "should be able to be created using the 'reference' method" do
      @aspect.reference(:exec, "whoami").to_ref.should == ['exec', 'whoami']
    end

    it "should be able to be created using a call to the named method with only one arg" do
      @aspect.exec("whoami").to_ref.should == ['exec', 'whoami']
    end

  end

  describe "facts" do
    before(:each) do
      @manifest = BlankManifest.new
      @aspect = @manifest.role :debug do
        exec "whoami", :command => "/usr/bin/whoami > /tmp/whoami.txt"
      end
    end

    it "should be able to reference the facts inside an aspect" do
      @aspect.facts.should == Facter.to_hash
    end

    it "should be able to be created using a call to the named method with only one arg" do
      @aspect.exec("whoami").to_ref.should == ['exec', 'whoami']
    end

  end

end

describe "Executing a manifest" do
  before(:each) do
    begin
      File.delete("/tmp/uname.txt")
      File.delete("/tmp/whoami.txt")
    rescue
    end
    @manifest = ClassLevelRole.new
    @manifest.role "myuname" do
      exec "uname", :command => "/usr/bin/uname > /tmp/uname.txt"
    end
  end

  it "should perform all tasks" do
    @manifest.run
    File.read("/tmp/whoami.txt").should == `whoami`
    File.read("/tmp/uname.txt").should == `uname`
  end

  it "should not be able to be run twice" do
    lambda do
      @manifest.run
    end.should_not(raise_error)
    lambda do
      @manifest.run
    end.should(raise_error)
  end

end

describe "Multiple manifests inherited from the same parent" do

  before(:each) do
    begin
      File.delete("/tmp/uname1.txt")
      File.delete("/tmp/uname2.txt")
    rescue
    end
    class ManifestOne < BlankManifest; end
    @manifest1 = ManifestOne.new
    @manifest1.role "uname1" do
      exec "uname1", :command => "/usr/bin/uname > /tmp/uname1.txt"
    end
    class ManifestTwo < BlankManifest; end
    @manifest2 = ManifestTwo.new
    @manifest2.role "uname2" do
      exec "uname2", :command => "/usr/bin/uname > /tmp/uname2.txt"
    end
  end

  it "can be executed back to back" do
    lambda do
      @manifest1.run
    end.should_not(raise_error)
    lambda do
      @manifest2.run
    end.should_not(raise_error)
    File.read("/tmp/uname1.txt").should == `uname`
    File.read("/tmp/uname2.txt").should == `uname`
  end

end