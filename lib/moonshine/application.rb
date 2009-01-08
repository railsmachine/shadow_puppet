gem "activesupport"
require 'active_support/inflector'
require 'moonshine/manifest'
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
      @options = DEFAULT_OPTIONS.merge(YAML.load_file(app_config_file))
    end

    def update
      if File.exist?(path)
        execute "cd #{path} && git checkout #{@options[:branch]}"
      else
        execute "git clone #{@options[:uri]} #{path}"
        execute "cd #{path} && git checkout -b #{@options[:branch]}"
      end
      execute "cd #{path} && git pull origin #{@options[:branch]}"
    end

    def test_clone
      temp_path = "/tmp/#{Time.new.to_f.to_s.gsub(/\./,'')}.#{name}.moonshine_clone_test"
      execute "git clone #{@options[:uri]} #{temp_path}"
      execute "ls #{temp_path}"
      File.remove_entry_secure(temp_path)
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

    def raise_manifest_load_error
      raise LoadError, "Moonshine Manifests expected at #{manifest_path}, none found."
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