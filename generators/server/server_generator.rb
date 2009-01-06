require 'rbconfig'

class ServerGenerator < Rails::Generator::Base
  # DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
  #                             Config::CONFIG['ruby_install_name'])

  attr_reader :server_name

  def initialize(runtime_args, runtime_options = {})
    Dir.mkdir('lib/tasks') unless File.directory?('lib/tasks')

    @server_name = (args.shift || 'main')

    super
  end

  def manifest
    record do |m|
      # script_options     = { :chmod => 0755, :shebang => options[:shebang] == DEFAULT_SHEBANG ? nil : options[:shebang] 
      # m.file      'script/moonshine',   'moonshine.rb',    script_options

      m.directory 'config/moonshine'
      m.template  'server.rb',        "config/moonshine/#{server_name}.rb"
    end
  end

protected

  def banner
    "Usage: #{$0} server SERVERNAME"
  end

end