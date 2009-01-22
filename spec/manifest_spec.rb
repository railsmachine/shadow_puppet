require File.dirname(__FILE__) + '/spec_helper.rb'

describe "A manifest" do

  describe "when blank" do

    before(:each) do
      @manifest = BlankManifest.new
    end

    it "does nothing" do
      @manifest.class.recipes.should == []
    end

    it "returns true when executed" do
      @manifest.execute.should be_true
    end

  end

  describe "without specified recipes" do

    before(:each) do
      @manifest = NoOpManifest.new
    end

    it "is executable by default" do
      @manifest.should be_executable
    end

    describe "when calling instance methods" do

      before(:each) do
        @manifest.foo
      end

      it "creates resources" do
        @manifest.puppet_resources[Puppet::Type::Exec].keys.sort.should == ['foo']
      end

      describe "and then executing" do

        before(:each) do
          @manifest = @manifest.execute
        end

        it "returns true" do
          @manifest.should be_true
        end

      end

    end

  end

  describe "when recipes aren't fullfilled" do

    before(:each) do
      @manifest = RequirementsNotMet.new
    end

    it "returns false when executed" do
      @manifest.execute.should be_false
    end

  end

  describe "in general" do

    before(:each) do
      @manifest = RequiresMetViaMethods.new
    end

    it "knows what it's supposed to do" do
      @manifest.class.recipes.should == [[:foo, {}], [:bar, {}]]
    end

    describe 'when evaluated' do

      it "calls specified methods" do
        @manifest.should_receive(:foo)
        @manifest.should_receive(:bar)
        @manifest.send(:evaluate_recipes)
      end

      it "creates new resources" do
        @manifest.should_receive(:new_resource).with(Puppet::Type::Exec, 'foo', :command => '/usr/bin/true').exactly(1).times
        @manifest.should_receive(:new_resource).with(Puppet::Type::Exec, 'bar', :command => '/usr/bin/true').exactly(1).times
        @manifest.send(:evaluate_recipes)
      end

      it "creates new resources" do
        @manifest.send(:evaluate_recipes)
        @manifest.puppet_resources[Puppet::Type::Exec].keys.sort.should == ['bar', 'foo']
      end

      it "can acess a flat array of resources" do
        @manifest.send(:flat_resources).should == []
      end

      describe "with arguments passed to recpie" do

        before(:each) do
          @manifest = PassingArguments.new
        end

        it "passes them to the methods" do
          @manifest.send(:evaluate_recipes)
          @manifest.puppet_resources[Puppet::Type::Exec].keys.sort.should == ['bar']
        end

      end

    end

    describe "when executed" do

      it "calls evaluate_recipes and apply" do
        @manifest.should_receive(:evaluate_recipes)
        @manifest.should_receive(:apply)
        @manifest.execute
      end

      it "returns true" do
        @manifest.execute.should be_true
      end

      it "cannot be executed again" do
        @manifest.execute.should be_true
        @manifest.execute.should be_false
      end

    end

  end

end