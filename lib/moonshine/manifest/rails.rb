require 'moonshine'
require 'moonshine/manifest'

module Moonshine
  class Manifest
    class Rails
      def initialize(application)
        manifest = Moonshine::Manifest.new(application)

        manifest.role :webserver do
          file "/tmp/testone", :content => "yaytest3"
        end

        manifest.role :mysql do
          package "mysql-server", :ensure => "installed"
          package "libmysql-ruby", :ensure => "installed"
        end

        manifest.roles :webserver, :mysql
      end
    end
  end
end