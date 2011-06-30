describe "ShadowPuppet's cli" do
  before(:all) do
    @root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    @output = `#{@root}/bin/shadow_puppet #{@root}/spec/fixtures/cli_spec_manifest.rb echo=works`
  end

  it "accepts env variables on the end of the command line" do
    @output.should =~ /notice: \/Exec\[from_env\]\/returns: works/
  end
end