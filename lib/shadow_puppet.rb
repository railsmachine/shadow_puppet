require 'puppet'
require 'configatron'
require 'erb'
require File.join(File.dirname(__FILE__) + '/shadow_puppet', 'core_ext.rb')
require File.join(File.dirname(__FILE__) + '/shadow_puppet', 'manifest.rb')

class ShadowPuppet::Manifest::Setup < ShadowPuppet::Manifest
  recipe :setup_directories

  def setup_directories()
    if Process.uid == 0
      file "/var/shadow_puppet",
        :ensure => "directory",
        :backup => false
      file "/etc/shadow_puppet",
        :ensure => "directory",
        :backup => false
    else
      file ENV["HOME"] + "/.shadow_puppet",
        :ensure => "directory",
        :backup => false
      file ENV["HOME"] + "/.shadow_puppet/var",
        :ensure   => "directory",
        :backup   => false,
        :require  => file(ENV["HOME"] + "/.shadow_puppet")
    end
  end
end

setup = ShadowPuppet::Manifest::Setup.new
setup.execute