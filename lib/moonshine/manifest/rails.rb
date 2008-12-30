require 'moonshine'
require 'moonshine/manifest'

class Moonshine::Manifest::Rails < Moonshine::Manifest
  def run

    manifest.role :rails do

      group "rails",
        :ensure => "present",
        :gid => 1001,
        :allowdupe => false

      user "rails",
        :ensure => "present",
        :uid => 1001,
        :gid => 1001,
        :home => "/srv/rails",
        :shell => "/bin/bash",
        :allowdupe => false,
        :notify => reference(:exec, "passwd-rails")

      file "/srv/rails",
        :ensure => "directory",
        :owner => "rails",
        :group => "rails"

      exec 'passwd-rails',
        :command         => "/usr/sbin/usermod -p `mkpasswd PASSWORD` rails",
        :refreshonly     => true

    end

    manifest.role :moonshine do

      Facter.to_hash[:moonshine].each do |application, config|
        app_root = "/srv/rails/#{application}"

        #ensure git repo is present

        #ensure mysql database is present

        #ensure apache config is present

        #if specified branch has changed, create timestamped branch and pull in changes

        #run rake moonshine

          #run rake moonshine:pre

            #rake gems:install

            #rake db:migrate

          #run rake moonshine:restart

          #run rake moonshine:post

        exec "restart-passenger",
            :command         => "touch #{app_root}/tmp/restart.txt",
            :refreshonly     => true

        #parse database.yml if one exists. if not, create one.

        exec "create-moonshine-db-#{application}",
            :command         => "/usr/bin/mysqladmin create #{application}",
            :unless          => "/usr/bin/mysqlcheck -s #{application}",
            :notify          => reference(:exec, "create-moonshine-user-#{application}")

        exec "create-moonshine-user-#{application}",
            :command         => "/usr/bin/mysql -e 'grant all privileges on #{application}.* to #{application}@localhost identified by \"password\"'",
            :refreshonly     => true

      end

    end

    manifest.role :debug do
      file "/tmp/facts.yaml", :content => YAML.dump(Facter.to_hash)
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
          :require         => reference(:package, "apache2.2-common")

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

    manifest.roles :webserver, :utils, :mysql, :debug, :rails
  end
end