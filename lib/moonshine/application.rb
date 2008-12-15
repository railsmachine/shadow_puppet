module Moonshine

  class Application

    attr_reader :name

    DEFAULT_OPTIONS = {
      :branch         => "release",
      :strategy       => :internal
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
      factpath = File.expand_path(File.join(File.dirname(__FILE__), '..', 'facts'))
      if @options[:strategy] == :internal
        manifest = File.expand_path(File.join(File.dirname(__FILE__), '..', 'moonshine.pp'))
        execute "puppet --factpath #{factpath} #{manifest}"
      else
        #other node definition strategies?
      end
    end

  protected

    def path
      @path ||= "/var/lib/moonshine/#{name}"
    end

    def setup
      raise if @name == ""
    end

    def execute(command)
      puts `#{command}`.chomp
    end

  end

end