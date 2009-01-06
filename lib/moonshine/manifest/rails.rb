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
        :allowdupe => false

      file "/srv/rails",
        :ensure => "directory",
        :owner => "rails",
        :group => "rails"

      exec 'passwd-rails',
        :command         => "/usr/sbin/usermod -p `mkpasswd PASSWORD` rails",
        :require         => reference(:package, "whois"),
        :refreshonly     => true,
        :subscribe       => reference(:user, "rails")

      package "rubygems", :ensure => "installed"

      package "rails", :ensure => "installed", :provider => "gem"

    end

    manifest.role :moonshine do

      Facter.to_hash["moonshine"].each do |application, config|
        app_root = "/srv/rails/#{application}"
        repo_path = "/var/lib/moonshine/applications/#{applications}"

        exec "#{application}-begin",
          :command  => "/bin/true",
          :before   => reference(:exec, "#{application}-setup")

        exec "#{application}-setup",
          :command => "/bin/true",
          :require => [
            reference(:user, "rails"),
            reference(:file, "/srv/rails"),
            reference(:file, "#{application}-vhost"),
            reference(:package, "rails")
          ],
          :before => [
            reference(:exec, "#{application}-clone"),
            reference(:exec, "#{application}-update")
          ]

        exec "#{application}-update",
          :command  => "/bin/true",
          :onlyif   => "/usr/bin/test -d #{app_root}",
          :before   => reference(:exec, "#{application}-finalize-update")

        exec "#{application}-clone",
          :command  => "/bin/true",
          :unless   => "/usr/bin/test -d #{app_root}",
          :before   => reference(:exec, "#{application}-finalize-update")

        exec "#{application}-finalize-update",
          :command  => "/bin/true",
          :before   => reference(:exec, "#{application}-restart")

        exec "#{application}-restart",
          :command  => "/bin/true",
          :before   => reference(:exec, "#{application}-finish")

        exec "#{application}-finish",
          :command => "/bin/true"

        #setup

        #TODO parse database.yml if one exists. if not, create one.

        exec "#{application}-db",
          :command      => "/usr/bin/mysqladmin create #{application}_production",
          :unless       => "/usr/bin/mysqlcheck -s #{application}_production",
          :require      => reference(:service, "mysql"),
          :refreshonly  => true,
          :subscribe    => reference(:exec, "#{application}-setup")

        exec "#{application}-db-user",
          :command      => "/usr/bin/mysql -e 'grant all privileges on #{application}_production.* to #{application}@localhost identified by \"password\"'",
          :refreshonly  => true,
          :subscribe    => reference(:exec, "#{application}-db")

        #apache config

        file "#{application}-vhost",
          :path     => "/etc/apache2/sites-available/#{application}",
          :content  => ERB.new(File.read(File.join(File.dirname(__FILE__), '..', '..', 'templates', 'vhost.conf.erb'))).result(binding),
          :require  => reference(:service, "apache2")

        exec "#{application}-enable-vhost",
          :command      => "/usr/sbin/a2dissite default && /usr/sbin/a2ensite #{application}",
          :refreshonly  => true,
          :notify       => reference(:service, "apache2"),
          :subscribe    => reference(:exec, "#{application}-vhost")

        #clone

        exec "#{application}-clone-repo",
          :command      => "/usr/bin/git clone #{repo_path} #{app_root}",
          :creates      => app_root,
          :require      => reference(:exec, "#{application}-repo-perms"),
          :refreshonly  => true,
          :user         => "rails",
          :subscribe    => reference(:exec, "#{application}-clone")

        #update

        exec "#{application}-update-repo",
          :cwd          => app_root,
          :command      => "/bin/true",
          :unless       => "/usr/bin/git checkout #{config[:branch]} && /usr/bin/git pull origin #{config[:branch]} 2> /dev/null | grep 'up-to-date' > /dev/null",
          :require      => reference(:exec, "#{application}-repo-perms"),
          :refreshonly  => true,
          :user         => "rails",
          :subscribe    => reference(:exec, "#{application}-update")

        exec "#{application}-repo-perms",
          :command      => "/bin/chgrp -R rails #{repo_path}",
          :refreshonly  => true

        #finalize-update

        exec "#{application}-migrate",
          :cwd          => app_root,
          :environment  => "RAILS_ENV=production",
          :command      => "/usr/bin/rake db:migrate",
          :refreshonly  => true,
          :user         => "rails",
          :subscribe    => reference(:exec, "#{application}-finalize-update")

        exec "#{application}-create-release-branch",
          :cwd          => app_root,
          :command      => "/usr/bin/git checkout -b `date -u +%Y%m%d%H%M%N`",
          :refreshonly  => true,
          :user         => "rails",
          :subscribe    => reference(:exec, "#{application}-finalize-update")

        #run rake moonshine

          #run rake moonshine:pre

            #rake gems:install

            #rake db:migrate

          #run rake moonshine:restart

          #run rake moonshine:post

        exec "#{application}-restart-passenger",
            :command      => "/usr/bin/touch #{app_root}/tmp/restart.txt",
            :refreshonly  => true,
            :user         => "rails",
            :subscribe    => reference(:exec, "#{application}-restart")

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
      ).each do |p|
        package p,
          :ensure => "installed",
          :before => reference(:service, "apache2")
      end

      service "apache2",
          :ensure          => "running",
          :enable          => true,
          :hasrestart      => true,
          :hasstatus       => true

    end

    manifest.role :mysql do

      %w(
        mysql-server
        libmysql-ruby
      ).each do |p|
        package p,
          :ensure => "installed",
          :before => reference(:service, "mysql")
      end

      service "mysql",
          :ensure          => "running",
          :enable          => true,
          :hasrestart      => true,
          :hasstatus       => true
    end

    manifest.roles :webserver, :utils, :mysql, :moonshine, :rails
  end
end