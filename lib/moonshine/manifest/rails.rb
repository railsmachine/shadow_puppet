require 'moonshine'
require 'moonshine/manifest'

class Moonshine::Manifest::Rails < Moonshine::Manifest
  def run
    manifest.role :rails do

      group "rails",
        :ensure => "present",
        :allowdupe => false,
        :require => reference(:user, "rails")

      user "rails",
        :ensure => "present",
        :home => "/srv/rails",
        :shell => "/bin/bash",
        :groups => "admin",
        :allowdupe => false,
        :notify => reference(:exec, "passwd-rails")

      file "/srv/rails",
        :ensure => "directory",
        :owner => "rails",
        :group => "rails"

      exec 'passwd-rails',
        :command         => "/usr/sbin/usermod -p `mkpasswd PASSWORD` rails",
        :require         => reference(:package, "whois"),
        :refreshonly     => true

      package "rubygems", :ensure => "installed"

      package "rails", :ensure => "installed", :provider => "gem"

    end

    manifest.role :moonshine do

      Facter.to_hash["moonshine"].each do |application, config|
        app_root = "/srv/rails/#{application}"
        repo_path = "/var/lib/moonshine/applications/#{applications}"

        exec "#{application}-begin"
          :command  => "/bin/true",
          :before   => reference(:exec, "#{application}-setup")

        exec "#{application}-setup"
          :command => "/bin/true",
          :require => [
            reference(:user, "rails"),
            reference(:file, "/srv/rails"),
            reference(:exec, "#{application}-db"),
            reference(:file, "#{application}-vhost"),
            reference(:package, "libapache2-mod-passenger"),
            reference(:package, "rails")
          ],
          :before => [
            reference(:exec, "#{application}-clone"),
            reference(:exec, "#{application}-update")
          ]

        exec "#{application}-update"
          :command  => "/bin/true",
          :onlyif   => "/usr/bin/test -d #{app_root}",
          :require => [
            reference(:exec, "#{application}-update-repo")
          ],
          :before   => reference(:exec, "#{application}-finalize-update")

        exec "#{application}-clone"
          :command  => "/bin/true",
          :unless   => "/usr/bin/test -d #{app_root}",
          :require => [
            reference(:exec, "#{application}-clone-repo")
          ],
          :before   => reference(:exec, "#{application}-finalize-update")

        exec "#{application}-finalize-update"
          :command => "/bin/true",
          :require => [
            reference(:exec, "#{application}-migrate"),
            reference(:exec, "#{application}-create-release-branch")
          ],
          :before => reference(:exec, "#{application}-restart")

        exec "#{application}-restart"
          :command => "/bin/true",
          :require => [
            reference(:exec, "#{application}-restart-passenger")
          ],
          :before => reference(:exec, "#{application}-finish")

        exec "#{application}-finish"
          :command => "/bin/true"

        #setup

        #TODO parse database.yml if one exists. if not, create one.

        exec "#{application}-db",
            :command      => "/usr/bin/mysqladmin create #{application}_production",
            :unless       => "/usr/bin/mysqlcheck -s #{application}_production",
            :require      => reference(:service, "mysql"),
            :notify       => reference(:exec, "#{application}-db-user"),
            :refreshonly  => true

        exec "#{application}-db-user",
            :command      => "/usr/bin/mysql -e 'grant all privileges on #{application}_production.* to #{application}@localhost identified by \"password\"'",
            :refreshonly  => true

        #apache config

        file "#{application}-vhost",
          :path         => "/etc/apache2/sites-available/#{application}",
          :content      => ERB.new(File.read(File.join(File.dirname(__FILE__), '..', '..', 'templates', 'vhost.conf.erb'))).result(binding),
          :require      => reference(:package, "apache2.2-common"),
          :refreshonly  => true,
          :notify       => reference(:exec, "#{application}-enable-vhost")

        exec "#{application}-enable-vhost",
            :command      => "/usr/sbin/a2ensite #{application}",
            :refreshonly  => true,
            :notify       => reference(:service, "apache2")

        #clone

        exec "#{application}-clone-repo",
          :command      => "/usr/bin/git clone #{repo_path} #{app_root}",
          :creates      => app_root,
          :require      => reference(:exec, "#{application}-repo-perms"),
          :refreshonly  => true,
          :user         => "rails"

        #update

        exec "#{application}-update-repo",
          :cwd          => app_root,
          :command      => "/bin/true",
          :unless       => "/usr/bin/git checkout #{config[:branch]} && /usr/bin/git pull origin #{config[:branch]} 2> /dev/null | grep 'up-to-date' > /dev/null",
          :require      => reference(:exec, "#{application}-repo-perms"),
          :refreshonly  => true,
          :user         => "rails"

        exec "#{application}-repo-perms",
          :command      => "/bin/chgrp -R rails #{repo_path}",
          :refreshonly  => true

        #finalize-update

        exec "#{application}-migrate",
          :cwd          => app_root,
          :command      => "RAILS_ENV=production rake:db:migrate",
          :refreshonly  => true,
          :user         => "rails"

        exec "#{application}-create-release-branch",
          :cwd          => app_root,
          :command      => "/usr/bin/git checkout -b `date -u +%Y%m%d%H%M%N`",
          :refreshonly  => true,
          :user         => "rails"

        #run rake moonshine

          #run rake moonshine:pre

            #rake gems:install

            #rake db:migrate

          #run rake moonshine:restart

          #run rake moonshine:post

        exec "#{application}-restart-passenger",
            :command      => "/usr/bin/touch #{app_root}/tmp/restart.txt",
            :refreshonly  => true,
            :user         => "rails"

      end

    end

    manifest.role :debug do
      file "/tmp/facts.yaml", :content => YAML.dump(Facter.to_hash)
      exec "whoami", :command => "/usr/bin/whoami > /tmp/whoami.txt"
    end

    manifest.role :utils do

      %w(
        man
        curl
        wget
        vim
        whois
      ).each { |p| package p, :ensure => "installed" }

    end

    manifest.role :webserver do

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
      ).each { |p| package p, :ensure => "installed" }

      service "apache2",
          :ensure          => "running",
          :enable          => true,
          :hasrestart      => true,
          :hasstatus       => true,
          :require         => reference(:package, "apache2.2-common"),
          :before          => reference(:file, "disable-default-site")

      file "disable-default-site",
          :path     => "/etc/apache2/sites-enabled/000-default",
          :ensure   => "absent",
          :require  => reference(:package, "apache2.2-common"),
          :notify   => reference(:service, "apache2")

    end

    manifest.role :mysql do
      package "mysql-server", :ensure => "installed"
      package "libmysql-ruby", :ensure => "installed"
      service "mysql",
          :ensure          => "running",
          :enable          => true,
          :hasrestart      => true,
          :hasstatus       => true,
          :require         => reference(:package, "mysql-server")
    end

    manifest.roles :webserver, :utils, :mysql, :moonshine, :rails
  end
end