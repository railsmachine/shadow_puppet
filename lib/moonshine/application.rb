gem "activesupport"
require 'active_support/inflector'
require 'fileutils'

module Moonshine

  class Application

    attr_reader :name, :options, :config_file

    DEFAULT_OPTIONS = {
      :branch         => "release",
      :strategy       => :rails,
      :user           => "rails",
      :manifest_glob  => "config/moonshine/*.rb"
    }

    def initialize(app_config_file)
      @config_file = app_config_file
      @name = File.basename(app_config_file, ".conf").gsub(/\s*/,'')
      raise ArgumentError if @name == ""
      @update_manifest = MoonshineUpdateManifest.new
      @options = DEFAULT_OPTIONS.merge(YAML.load_file(app_config_file))
    end

    def update
      @update_manifest.update_application(@name, options)
      @update_manifest.run
    end

    def test_clone
      as_user(options[:user]) do
        while true
          begin
            puts("Press ENTER to test cloning #{@options[:uri]}")
            gets
            temp_path = "/tmp/#{Time.new.to_f.to_s.gsub(/\./,'')}.moonshine_clone_test"
            system("git clone #{@options[:uri]} #{temp_path}")
            system("ls #{temp_path}")
            FileUtils.remove_entry_secure(temp_path)
          rescue Exception => e
            puts "ERROR: #{e.class}"
          ensure
            puts("Was the clone successful? [Yn]")
            success = gets
            break if success.chomp.upcase != 'N'
          end
        end
      end
    end

    def apply
      if @options[:strategy] == :rails
        glob = Dir.glob(manifest_path)
        raise_manifest_load_error if glob == []
        glob.each do |manifest_path|
          #TODO: only load named servers
          klass = File.basename(manifest_path, ".rb")
          require manifest_path
          manifest = klass.classify.constantize.new(@name)
          manifest.run
        end
      else
        #other node definition strategies?
      end
    end

    def update_config_file
      f = File.new(config_file, "w")
      f.write(YAML.dump(options))
      f.close
    end

  protected

    def as_user(user, &block)
      require 'etc'
      begin
        old_euid = Process.euid
        old_user = ENV["USER"]
        old_home = ENV["HOME"]
        Process.uid = Etc.getpwnam(user).uid
        Process.euid = Etc.getpwnam(user).uid
        ENV["USER"] = user
        ENV["LOGNAME"] = user
        ENV["HOME"] = "/home/#{user}"
        yield
      rescue Exception => e
        raise e
      ensure
        Process.uid = old_euid
        Process.euid = old_euid
        ENV["USER"] = old_user
        ENV["LOGNAME"] = old_user
        ENV["HOME"] = old_home
      end
    end

    def raise_manifest_load_error
      raise LoadError, "Moonshine Manifests expected at #{manifest_path}, none found. \n\nPlease install the moonshine plugin into your app, and run ./script/generate server [ServerName]"
    end

    def manifest_path
      @manifest_path ||= File.join(path,"/#{@options[:manifest_glob]}")
    end

    def path
      @path ||= "/var/lib/moonshine/applications/#{name}"
    end

    def execute(command)
      `#{command}`.chomp
    end

  end

end