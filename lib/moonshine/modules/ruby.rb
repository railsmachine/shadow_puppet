module MoonshineRuby
  mattr_accessor :interpreter

  def ruby(interpreter, uri = "")
    self.interpreter = interpreter
    case interpreter
    when :enterprise

    tarball = uri.split("/").last
    stub = tarball.gsub(/\.tar\.gz/, '').gsub(/\.tgz/, '')

    role "ruby" do

      file "/var/lib/moonshine/packages",
        :ensure => "directory"

      package "wget", :ensure => "installed"

      package "apache2-prefork-dev", :ensure => "installed"

      exec "download-enterprise",
        :cwd      => "/var/lib/moonshine/packages",
        :command  => "/usr/bin/wget #{uri}",
        :creates  => "/var/lib/moonshine/packages/#{tarball}",
        :before   => [
          exec("untar-enterprise"),
          service("apache2")
        ],
        :require    => [
           package("apache2-prefork-dev"),
           package("libmysqlclient-dev"),
           package("build-essential"),
           package("zlib1g-dev"),
           package("libssl-dev")
         ]

      exec "untar-enterprise",
        :cwd          => "/var/lib/moonshine/packages",
        :command      => "/bin/tar xzvf /var/lib/moonshine/packages/#{tarball}",
        :creates      => "/var/lib/moonshine/packages/#{stub}",
        :refreshonly  => true,
        :subscribe    => exec("download-enterprise"),
        :before       => exec("install-enterprise")

      exec "install-enterprise",
        :command      => "/usr/bin/yes | /var/lib/moonshine/packages/#{stub}/installer -a /opt/#{stub}",
        :refreshonly  => true,
        :timeout      => "-1",
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
        :timeout      => "-1",
        :subscribe    => exec("symlink-rake"),
        :before       => exec("install-ruby")

      exec "install-ruby",
        :refreshonly  => true,
        :subscribe    => exec("install-passenger"),
        :command      => "/bin/true"

    end

    when :debian

    role "ruby" do

      file "/var/lib/moonshine/packages",
        :ensure => "directory"

        package "rubygems", :ensure => "installed"
        package "rake", :ensure => "installed"
        package "apache2-mpm-worker", :ensure => "installed"
        package "libapache2-mod-passenger",
          :ensure  => "installed",
          :require => package("apache2-mpm-worker")

        package "rubygems-update",
          :ensure   => "installed",
          :provider => "gem",
          :require  => [
            package("rubygems"),
            package("rake"),
            package("libapache2-mod-passenger")
          ]

        exec "update-rubygems",
          :command      => "/usr/bin/update_rubygems",
          :refreshonly  => true,
          :onlyif       => "/usr/bin/test -f /usr/bin/update_rubygems",
          :subscribe    => package("rubygems-update"),
          :before       => exec('install-ruby')

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