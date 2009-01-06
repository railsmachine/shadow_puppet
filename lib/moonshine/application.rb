module Moonshine

  class Application

    attr_reader :name

    DEFAULT_OPTIONS = {
      :branch         => "release",
      :strategy       => :rails,
      :manifest_glob  => "config/moonshine/*.rb"
    }

    def initialize(name = "", options = {})
      @name = name.gsub(/\s*/,'')
      @options = DEFAULT_OPTIONS.merge(options)
      setup
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

    def apply
      if @options[:strategy] == :rails
        require 'moonshine/manifest'
        glob = Dir.glob(manifest_path)
        raise_manifest_load_error if glob == []
        glob.each do |manifest|
          #TODO: only load named servers
          klass = File.basename(manifest, ".rb")
          require manifest
          applied_manifest = klass.classify.constantize.new
        end
      else
        #other node definition strategies?
      end
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

    def setup
      raise if @name == ""
    end

    def execute(command)
      `#{command}`.chomp
    end

  end

end