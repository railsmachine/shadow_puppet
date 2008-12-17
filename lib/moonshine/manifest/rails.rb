require 'moonshine'
require 'moonshine/manifest'

module Moonshine
  class Manifest
    class Rails
      def initialize(application)
        manifest = Moonshine::Manifest.new(application)

        file "/tmp/facts.yaml", :contents => YAML.dump(Facter.to_hash)

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
              :require         => Puppet::Parser::Resource::Reference.new(:type => "package", :title => "apache2.2-common")

        end

        manifest.role :mysql do
          package "mysql-server", :ensure => "installed"
          package "libmysql-ruby", :ensure => "installed"
          service "mysql",
              :ensure          => "running",
              :enable          => true,
              :hasrestart      => true,
              :hasstatus       => true,
              :require         => Puppet::Parser::Resource::Reference.new(:type => "package", :title => "mysql-server")
          exec 'create-rails-db',
              :command         => "/usr/bin/mysqladmin create rails",
              :unless          => "/usr/bin/mysqlcheck -s rails",
              :notify          => Puppet::Parser::Resource::Reference.new(:type => "exec", :title => "create-rails-user")
          exec "create-rails-user",
              :command         => "/usr/bin/mysql -e 'grant all privileges on rails.* to rails@localhost identified by \"rails\"'",
              :refreshonly     => true
        end

        manifest.roles :webserver, :mysql
      end
    end
  end
end