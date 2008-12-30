module Moonshine

  class Application

    attr_reader :name

    DEFAULT_OPTIONS = {
      :branch         => "release",
      :strategy       => :rails
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
        rails = Moonshine::Manifest::Rails.new(@name)
        #parse the environment configuration of the app

        # config.packages
        # config.server "foo.railsmachina.com", :rails
        # config.server "foodb.railsmachina.com", :mysql

        #update the stock puppet manifest with whatever's been generated from the config
        rails.run
      else
        #other node definition strategies?
      end
    end

  protected

    def path
      @path ||= "/srv/moonshine/#{name}"
    end

    def setup
      raise if @name == ""
    end

    def execute(command)
      `#{command}`.chomp
    end

  end

end