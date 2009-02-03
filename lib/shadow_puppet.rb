require File.join(File.dirname(__FILE__) + '/shadow_puppet', 'manifest.rb')

class ShadowPuppet::Manifest::Setup < ShadowPuppet::Manifest
  recipe :setup_directories

  def setup_directories()
    if Process.uid == 0
      file "/var/puppet",
        :ensure => "directory",
        :backup => false
    else
      file ENV["HOME"] + "/.puppet",
        :ensure => "directory",
        :backup => false
      file ENV["HOME"] + "/.puppet/var",
        :ensure   => "directory",
        :backup   => false,
        :require  => file(ENV["HOME"] + "/.puppet")
    end
  end
end

setup = ShadowPuppet::Manifest::Setup.new
setup.execute