require 'optparse'
require 'yaml'
require 'logger'

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
      highline = HighLine.new
      @logger.info "No application found, configuring one"
      name = highline.ask("What's the name of the application you'd like to add?")
      name = name.gsub(/\s*/,'')
      uri = highline.ask("Where is the application's git repo?")
      branch = highline.ask("Which branch of your application would you like to deploy?  ") { |q| q.default = "release" }
      options = { :uri => uri, :branch => branch }
      f = File.new("/etc/moonshine/#{name}.conf", "w")
      f.write(YAML.dump(options))
      f.close
    end

    def load_applications
      @applications = []
      configure_first_application if Dir.glob("/etc/moonshine/*.conf") == []
      Dir.glob("/etc/moonshine/*.conf").each do |application|
        begin
          name = File.basename(application, ".conf")
          application = Moonshine::Application.new(name, YAML.load_file(application))
          @applications << application
          @logger.info "Loaded #{name}"
        rescue
          @logger.error "Error loading #{name}"
        end
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
      unless File.exist?("/srv/moonshine")
        unless File.exist?("/srv")
          Dir.mkdir("/srv")
        end
        Dir.mkdir("srv/moonshine")
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

    def update
      @logger.info "Checking for manifest updates..."
      @applications.each do |app|
        @logger.info "Checking #{app.name}"
        app.update
      end
    end

    def apply
      @logger.info "Applying manifests locally..."
      @applications.each do |app|
        @logger.info "Applying #{app.name}"
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