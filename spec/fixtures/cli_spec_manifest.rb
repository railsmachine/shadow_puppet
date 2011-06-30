class CliSpecManifest < ShadowPuppet::Manifest
  def test_setting_env
    exec :from_env, :command => "echo #{ENV['echo']}", :logoutput => true
    exec :normal, :command => "echo test", :logoutput => true
  end
  recipe :test_setting_env
end