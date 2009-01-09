#    class UrServer < Moonshine::Manifest::Rails
#      user "rails"
#      gems_from_rails_environment
#      service("memcached", %w(memcache libmemcached))
#
#      role :something_else do
#        exec "foo", :command => "echo 'normal puppet stuff here' > /tmp/test"
#      end
#    end
#    server = UrServer.new("name_of_application")
#    server.runclass Moonshine::Manifest::Rails < Moonshine::Manifest
class Moonshine::Manifest::Rails < Moonshine::Manifest
  # don't think this is needed anymore
  # user(moonshine_user)

  role :rails do

    file "/srv/rails",
      :ensure => "directory",
      :owner => moonshine_user,
      :group => moonshine_user

    package "rubygems", :ensure => "installed"

    package "rails", :ensure => "installed", :provider => "gem"

  end

  role :moonshine do

    facts["moonshine"].each do |application, config|
      app_root = "/srv/rails/#{application}"
      repo_path = "/var/lib/moonshine/applications/#{applications}"

      exec "#{application}-begin",
        :command  => "/bin/true",
        :require => [
          user(moonshine_user),
          file("/srv/rails"),
          package("rails"),
          service("apache2"),
          service("mysql")
        ],
        :before   => exec("#{application}-setup")

      exec "#{application}-setup",
        :command => "/bin/true",
        :require => [
          file("#{application}-vhost")
        ],
        :before => [
          exec("#{application}-clone"),
          exec("#{application}-update")
        ]

      exec "#{application}-update",
        :command  => "/bin/true",
        :onlyif   => "/usr/bin/test -d #{app_root}",
        :before   => exec("#{application}-finalize-update")

      exec "#{application}-clone",
        :command  => "/bin/true",
        :unless   => "/usr/bin/test -d #{app_root}",
        :before   => exec("#{application}-finalize-update")

      exec "#{application}-finalize-update",
        :command  => "/bin/true",
        :before   => exec("#{application}-restart")

      exec "#{application}-restart",
        :command  => "/bin/true",
        :before   => exec("#{application}-finish")

      exec "#{application}-finish",
        :command => "/bin/true"

      #setup

      #TODO parse database.yml if one exists. if not, create one.

      exec "#{application}-db",
        :command      => "/usr/bin/mysqladmin create #{application}_production",
        :unless       => "/usr/bin/mysqlcheck -s #{application}_production",
        :require      => service("mysql"),
        :refreshonly  => true,
        :subscribe    => exec("#{application}-setup"),
        :before       => [
          exec("#{application}-clone"),
          exec("#{application}-update")
        ]

      exec "#{application}-db-user",
        :command      => "/usr/bin/mysql -e 'grant all privileges on #{application}_production.* to #{application}@localhost identified by \"password\"'",
        :refreshonly  => true,
        :subscribe    => exec("#{application}-db"),
        :before       => [
          exec("#{application}-clone"),
          exec("#{application}-update")
        ]

      #apache config

      file "#{application}-vhost",
        :path     => "/etc/apache2/sites-available/#{application}",
        :content  => ERB.new(File.read(File.join(File.dirname(__FILE__), '..', '..', 'templates', 'vhost.conf.erb'))).result(binding),
        :require  => package("apache2.2-common")

      exec "#{application}-enable-vhost",
        :command      => "/usr/sbin/a2dissite default && /usr/sbin/a2ensite #{application}",
        :refreshonly  => true,
        :notify       => service("apache2"),
        :subscribe    => file("#{application}-vhost"),
        :before       => [
          exec("#{application}-clone"),
          exec("#{application}-update")
        ]

      #clone

      exec "#{application}-clone-repo",
        :command      => "/usr/bin/git clone #{repo_path} #{app_root} && cd #{app_root} && /usr/bin/git checkout -b release",
        :creates      => app_root,
        :refreshonly  => true,
        :user         => moonshine_user,
        :group        => 'moonshine',
        :subscribe    => exec("#{application}-clone"),
        :before       => exec("#{application}-finalize-update")

      #update

      exec "#{application}-update-repo",
        :cwd          => app_root,
        :command      => "/usr/bin/git checkout #{config[:branch]} && /usr/bin/git pull origin #{config[:branch]}",
        :refreshonly  => true,
        :user         => moonshine_user,
        :group        => 'moonshine',
        :subscribe    => exec("#{application}-update"),
        :before       => exec("#{application}-finalize-update")

      exec "#{application}-repo-perms",
        :command      => "/bin/chgrp -R #{moonshine_user} #{repo_path}",
        :refreshonly  => true,
        :subscribe    => exec("#{application}-setup"),
        :before       => [
          exec("#{application}-clone"),
          exec("#{application}-update")
        ]

      #finalize-update

      exec "#{application}-migrate",
        :cwd          => app_root,
        :environment  => "RAILS_ENV=production",
        :command      => "/usr/bin/rake db:migrate",
        :refreshonly  => true,
        :user         => moonshine_user,
        :group        => 'moonshine',
        :subscribe    => exec("#{application}-finalize-update"),
        :before       => exec("#{application}-restart")

      exec "#{application}-create-release-branch",
        :cwd          => app_root,
        :command      => "/usr/bin/git checkout -b `date -u +%Y%m%d%H%M%N`",
        :refreshonly  => true,
        :user         => moonshine_user,
        :group        => 'moonshine',
        :subscribe    => exec("#{application}-finalize-update"),
        :before       => exec("#{application}-migrate")

      #run rake moonshine

        #run rake moonshine:pre

          #rake gems:install

          #rake db:migrate

        #run rake moonshine:restart

        #run rake moonshine:post

      exec "#{application}-restart-passenger",
          :command      => "/usr/bin/touch #{app_root}/tmp/restart.txt",
          :refreshonly  => true,
          :user         => moonshine_user,
          :group        => 'moonshine',
          :subscribe    => exec("#{application}-restart"),
          :before       => exec("#{application}-finish")

    end

  end

  role :debug do
    file "/tmp/facts.yaml", :content => YAML.dump(Facter.to_hash)
    exec "whoami", :command => "/usr/bin/whoami > /tmp/whoami.txt"
  end

  role :utils do

    %w(
      man
      curl
      wget
      vim
      whois
    ).each { |p| package p, :ensure => "installed" }

  end

  service "mysql",
    %w(
      mysql-server
      libmysql-ruby
    )

  service "apache2",
    %w(
      apache2-mpm-worker
      apache2-utils
      apache2.2-common
      libapache2-mod-passenger
      libapr1
      libaprutil1
      libpq5
      openssl-blacklist
      ssl-cert
    )

end