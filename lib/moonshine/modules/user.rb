module MoonshineUser
  mattr_accessor :current_moonshine_user

  def user(name = "")
    return if name.nil?
    name = name.gsub(/\s*/,'')
    return if name == ''
    self.current_moonshine_user = name
    self.recipe :moonshine_user, :name => name
    send(:include, InstanceMethods)
  end

  module InstanceMethods
    def current_moonshine_user
      self.class.current_moonshine_user
    end

    def moonshine_user(options = {})
      name = options[:name]
      home = "/home/#{name}"
      %w(
        makepasswd
        whois
      ).each { |p| package p, :ensure => "installed" }

      group name,
        :ensure     => "present",
        :allowdupe  => false,
        :require    => user(name)

      user name,
        :ensure     => "present",
        :shell      => "/bin/bash",
        :groups     => ["admin", "moonshine"],
        :allowdupe  => false,
        :before     => [
          file("#{home}/.ssh"),
          file("#{home}")
        ]

      file "#{home}",
        :ensure => "directory",
        :mode   => "755",
        :owner  => name,
        :group  => name,
        :before => [
          exec("#{name}-ssh-dsa"),
          exec("#{name}-ssh-rsa")
        ]

      file "#{home}/.ssh",
        :ensure => "directory",
        :mode   => "700",
        :owner  => name,
        :group  => name,
        :before => [
          exec("#{name}-ssh-dsa"),
          exec("#{name}-ssh-rsa")
        ]

      exec "#{name}-ssh-rsa",
        :command      => "/usr/bin/ssh-keygen -f #{home}/.ssh/id_rsa -t rsa -N '' -q",
        :unless       => "/usr/bin/test -f #{home}/.ssh/id_rsa",
        :refreshonly  => true,
        :subscribe    => user(name),
        :user         => name

      exec "#{name}-generate-passwd",
        :command      => "/usr/bin/makepasswd --char=10 > /root/#{name}_password.txt",
        :require      => reference(:package, "makepasswd"),
        :refreshonly  => true,
        :subscribe    => user(name)

      exec "#{name}-set-passwd",
        :command      => "/usr/sbin/usermod -p `mkpasswd $(/bin/cat /root/#{name}_password.txt)` #{name}",
        :require      => package("whois"),
        :refreshonly  => true,
        :subscribe    => exec("#{name}-generate-passwd")
    end
  end

end
Moonshine::Manifest.send(:extend, MoonshineUser)