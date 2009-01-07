module MoonshineUser
  mattr_accessor :user

  def moonshine_user(user)
    self.user = user
    role "#{user}-user" do
      %w(
        makepasswd
        whois
      ).each { |p| package p, :ensure => "installed" }

      group user,
        :ensure => "present",
        :allowdupe => false,
        :require => reference(:user, user)

      user user,
        :ensure => "present",
        :shell => "/bin/bash",
        :groups => "admin",
        :allowdupe => false

      exec "#{user}-generate-passwd",
        :command         => "/usr/sbin/makepasswd --char=10 > /root/#{user}_password.txt",
        :require         => reference(:package, "makepasswd"),
        :refreshonly     => true,
        :subscribe       => reference(:user, user)

      exec "#{user}-set-passwd",
        :command         => "/usr/sbin/usermod -p `mkpasswd $(/bin/cat /root/#{user}_password.txt)` #{user}",
        :require         => reference(:package, "whois"),
        :refreshonly     => true,
        :subscribe       => reference(:exec, "#{user}-generate-passwd")
    end
  end
end
Moonshine::Manifest.send(:extend, MoonshineUser)

module UserAspectMethods
  def moonshine_user
    MoonshineUser.user
  end
end
Puppet::DSL::Aspect.send(:include, UserAspectMethods)