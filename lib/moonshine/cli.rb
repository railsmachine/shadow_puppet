require 'optparse'
require 'yaml'
require 'logger'

class UserConfigurationManifest < Moonshine::Manifest
  include MoonshineUser
end

module Moonshine

  class CLI

    CONFIG_FILE = "/etc/moonshine.conf"

    DEFAULT_OPTIONS = {
      :daemonize  => false,
      :interval   => 30,
      :log        => '/var/log/moonshine.log',
      :log_level  => 1,
      :pid        => '/var/run/moonshine.pid'
    }

    def initialize(options)
      setup
      configure(options)
      init_logger
      load_applications
    end

    def configure(options)
      @options = {}
      @options.merge!(DEFAULT_OPTIONS)

      if File.exists?('/etc/moonshine.conf')
        config_file_options = YAML.load_file('/etc/moonshine.conf')
        if config_file_options
          config_file_options = config_file_options.inject({}) do |o, (key, value)|
            o[(key.to_sym rescue key) || key] = value
            o
          end
          @options.merge!(config_file_options)
        end
      end
      @options.merge!(options)
      @options
    end

    def configure_first_application
      require 'highline'
      console = HighLine.new

      console.say "Configuring first application"
      name = console.ask("Application name:")
      name = name.gsub(/\s*/,'')

      uri = console.ask("Git Repo: (ex. git@github.com:you/yourapp.git)")

      branch = console.ask("Deploy from branch:") { |q| q.default = "release" }

      user = console.ask("User: (this user will created if it doesn't already exist)") { |q| q.default = "rails" }
      setup_user(user)

      #save initial version of the config
      app_config_file = "/etc/moonshine/#{name}.conf"
      f = File.new(app_config_file, "w")
      f.write(YAML.dump({ :uri => uri, :branch => branch, :user => user }))
      f.close
      app = Moonshine::Application.new(app_config_file)

      rsa = File.read("/home/#{user}/.ssh/id_rsa.pub")
      console.say <<-HERE
Below is your SSH Public Key (/home/#{user}/.ssh/id_rsa.pub)

Please provide this key to the host of your Git Repository.

GitHub: http://github.com/guides/understanding-deploy-keys
Gitosis: http://scie.nti.st/2007/11/14/hosting-git-repositories-the-easy-and-secure-way

HERE
      console.say(rsa+"\n\n")

      app.test_clone

      app.update_config_file
    end

    def load_applications
      @applications = []
      configure_first_application if Dir.glob("/etc/moonshine/*.conf") == []
      Dir.glob("/etc/moonshine/*.conf").each do |app_config_file|
        @applications << Moonshine::Application.new(app_config_file)
        @logger.debug "Loaded #{app_config_file}"
      end
    end

    def run
      if @options[:daemonize]
        run_daemonized
      else
        run_once
      end
    end

 protected

    def setup
      unless File.exist?("/var/lib/moonshine/applications")
        unless File.exist?("/var/lib/moonshine")
          unless File.exist?("/var/lib")
            Dir.mkdir("/var/lib")
          end
          Dir.mkdir("/var/lib/moonshine")
        end
        Dir.mkdir("/var/lib/moonshine/applications")
      end
      unless File.exist?("/var/cache/moonshine")
        unless File.exist?("/var/cache")
          Dir.mkdir("/var/cache")
        end
        Dir.mkdir("/var/cache/moonshine")
      end
      unless File.exist?("/etc/moonshine")
        Dir.mkdir("/etc/moonshine")
      end
      unless File.exist?("/var/puppet")
        Dir.mkdir("/var/puppet")
      end
    end

    def setup_user(u)
      m = UserConfigurationManifest.new
      m.user(u)
      m.run
    end

    def update
      @logger.info "Updating manifests"
      @applications.each do |app|
        @logger.debug "  #{app.name}"
        app.update
      end
    end

    def apply
      @logger.info "Applying manifests"
      @applications.each do |app|
        @logger.debug "  #{app.name}"
        app.apply
      end
    end

    def run_daemonized
      # trap and ignore SIGHUP
      Signal.trap('HUP') {}

      pid = fork do
        begin
          # reset file descriptors
          STDIN.reopen "/dev/null"
          STDOUT.reopen(File.expand_path(@options[:log]), "a")
          STDERR.reopen STDOUT
          STDOUT.sync = true

          loop do
            run_once
            sleep @options[:interval]
            GC.start
          end

        rescue => e
          puts e.message
          puts e.backtrace.join("\n")
          abort "There was a fatal system error while starting moonshine (see above)"
        end
      end

      File.open(File.expand_path(@options[:pid]), 'w') { |f| f.write pid }

      ::Process.detach pid

      exit(0)
    end

    def run_once
      begin
        update
        apply
      rescue Exception => e
        if e.instance_of?(SystemExit)
          raise
        else
          @logger.error "\n======"
          @logger.error "Exception!"
          @logger.error e.inspect
          @logger.debug "\n\n" + e.backtrace.join("\n")
          @logger.error "======"
          exit(1) unless @options[:daemonize]
        end
      end
      nil
    end

    def init_logger
      if @options[:daemonize]
        @logger = Logger.new(@options[:log])
      else
        @logger = Logger.new(STDOUT)
      end
      @logger.level = @options[:log_level]
    end

  end

end