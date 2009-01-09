module MoonshineRuby
  mattr_accessor :interpreter

  def ruby(interpreter, uri = "")
    self.interpreter = interpreter
    begin
      tarball = uri.split("/").last
      stub = tarball.gsub(/\.tar\.gz/, '').gsub(/\.tgz/, '')
    rescue
    end
    case interpreter
    when :enterprise

    role "ruby" do

      file "/var/lib/moonshine/packages",
        :ensure => "directory"

      package "wget", :ensure => "installed"

      exec "download-enterprise",
        :cwd      => "/var/lib/moonshine/packages",
        :command  => "/usr/bin/wget #{uri}",
        :creates  => "/var/lib/moonshine/packages/#{tarball}",
        :before   => exec("untar-enterprise"),
        :require    => [
           package("apache2-prefork-dev"),
           package("libmysqlclient-dev"),
           package("build-essential"),
           package("zlib1g-dev"),
           package("libssl-dev")
         ]

      exec "untar-enterprise",
        :cwd          => "/var/lib/moonshine/packages",
        :command      => "/usr/bin/tar xzvf /var/lib/moonshine/packages/#{tarball}",
        :creates      => "/var/lib/moonshine/packages/#{tarball}",
        :refreshonly  => true,
        :subscribe    => exec("download-enterprise"),
        :before       => exec("install-enterprise")

      exec "install-enterprise",
        :command      => "/usr/bin/yes | /var/lib/moonshine/packages/#{stub}/installer -a /opt/#{stub}",
        :refreshonly  => true,
        :timeout      => -1,
        :subscribe    => exec("untar-enterprise"),
        :before       => exec("symlink-enterprise")

      exec "symlink-enterprise",
        :command      => "/bin/ln -fs /opt/#{stub} /opt/ree",
        :refreshonly  => true,
        :subscribe    => exec("install-enterprise"),
        :before       => exec("symlink-rake")

      exec "symlink-rake",
        :command      => "/bin/ln -fs /opt/ree/bin/rake /usr/bin/rake",
        :refreshonly  => true,
        :subscribe    => exec("symlink-enterprise"),
        :before       => exec("symlink-gem")

      exec "symlink-gem",
        :command      => "/bin/ln -fs /opt/ree/bin/gem /usr/bin/gem",
        :refreshonly  => true,
        :subscribe    => exec("symlink-rake"),
        :before       => exec("install-passenger")

      exec "install-passenger",
        :command      => "/usr/bin/yes /opt/ree/bin/passenger-install-apache2-module",
        :refreshonly  => true,
        :subscribe    => exec("symlink-rake"),
        :before       => exec("install-ruby")

      exec "install-ruby",
        :refreshonly  => true,
        :subscribe    => exec("install-passenger"),
        :command      => "/bin/true",
        :before       => service("apache2")

    end

    when :debian

    role "ruby" do

      file "/var/lib/moonshine/packages",
        :ensure => "directory"

        package "rubygems", :ensure => "installed"
        package "rake", :ensure => "installed"

        package "rubygems-update",
          :ensure   => "installed",
          :provider => "gem",
          :require  => package("rubygems")

        exec "update-rubygems",
          :command      => "/usr/bin/update_rubygems",
          :refreshonly  => true,
          :onlyif       => "/usr/bin/test -f /usr/bin/update_rubygems",
          :subscribe    => package("rubygems-update"),
          :before       => exec('fix-rubygems')

        exec "update-rubygems-var-lib",
          :command      => "/var/lib/gems/1.8/bin/update_rubygems",
          :refreshonly  => true,
          :onlyif       => "/usr/bin/test -f /var/lib/gems/1.8/bin/update_rubygems",
          :subscribe    => package("rubygems-update"),
          :before       => exec('install-ruby')

        exec "install-ruby",
          :command      => "/bin/true",
          :refreshonly  => true,
          :subscribe    => [
            exec("update-rubygems-var-lib"),
            exec("update-rubygems")
          ]

      end

    end
  end

end
Moonshine::Manifest.send(:extend, MoonshineRuby)