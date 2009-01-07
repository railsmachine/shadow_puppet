module MoonshineUser
  mattr_accessor :moonshine_user

  def user(name)
    self.moonshine_user = name
    role "#{name}-user" do
      %w(
        makepasswd
        whois
      ).each { |p| package p, :ensure => "installed" }

      group name,
        :ensure => "present",
        :allowdupe => false,
        :require => user(name)

      user name,
        :ensure => "present",
        :shell => "/bin/bash",
        :groups => "admin",
        :allowdupe => false

      exec "#{name}-generate-passwd",
        :command         => "/usr/bin/makepasswd --char=10 > /root/#{name}_password.txt",
        :require         => reference(:package, "makepasswd"),
        :refreshonly     => true,
        :subscribe       => user(name)

      exec "#{name}-set-passwd",
        :command         => "/usr/sbin/usermod -p `mkpasswd $(/bin/cat /root/#{name}_password.txt)` #{name}",
        :require         => package("whois"),
        :refreshonly     => true,
        :subscribe       => exec("#{name}-generate-passwd")
    end
  end
end
Moonshine::Manifest.send(:extend, MoonshineUser)

module UserAspectMethods
  def moonshine_user
    MoonshineUser.moonshine_user
  end
end
Puppet::DSL::Aspect.send(:include, UserAspectMethods)