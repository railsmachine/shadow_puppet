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

      it "applies our customizations to resources" do
        @manifest.puppet_resources[Puppet::Type::Exec]["foo"].params[:path].value.should == ENV["PATH"]
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

    it "has a configuration hash on the class" do
      @manifest.class.configuration[:foo].should == :bar
    end

    it "can access the same configuration hash on the instance" do
      @manifest.configuration[:foo].should == :bar
    end

    it "has a name" do
      @manifest.name.should == "#{@manifest.class}##{@manifest.object_id}"
    end

    describe 'when evaluated' do

      it "calls specified methods" do
        @manifest.should_receive(:foo)
        @manifest.should_receive(:bar)
        @manifest.send(:evaluate_recipes)
      end

      it "creates new resources" do
        @manifest.should_receive(:new_resource).with(Puppet::Type::Exec, 'foo', :command => 'true').exactly(1).times
        @manifest.should_receive(:new_resource).with(Puppet::Type::Exec, 'bar', :command => 'true').exactly(1).times
        @manifest.send(:evaluate_recipes)
      end

      it "creates new resources" do
        @manifest.send(:evaluate_recipes)
        @manifest.puppet_resources[Puppet::Type::Exec].keys.sort.should == ['bar', 'foo']
      end

      it "can acess a flat array of resources" do
        @manifest.send(:flat_resources).should == []
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

    describe "after execution" do

      before(:each) do
        @manifest = ProvidedViaModules.new
        @manifest.execute
      end

      it "allows creation of other similar resources" do
        m = PassingArguments.new
        m.execute.should be_true
      end

    end

  end

  describe "that subclasses an existing manifest" do

    before(:each) do
      @manifest = RequiresMetViaMethodsSubclass.new
    end

    it "inherits recipes from the parent class" do
      @manifest.class.recipes.map(&:first).should include(:foo, :bar)
    end

    it "appends recipes created in the subclass" do
      @manifest.class.recipes.map(&:first).should include(:baz)
    end

    it "merges it's configuration with that of the parent" do
      @manifest.class.configuration[:foo].should == :bar
      @manifest.class.configuration[:baz].should == :bar
    end

    it "is able to add configuration parameters on the instance" do
      @manifest.configuration = { :boo => :bar }
      @manifest.configuration[:boo].should == :bar
      @manifest.class.configuration[:boo].should == :bar
    end

  end

end