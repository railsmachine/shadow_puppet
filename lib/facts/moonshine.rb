require 'moonshine'
require 'facter'
require 'moonshine/application'

def applications
  apps = []
  Dir.glob("/etc/moonshine/*.conf").each do |application|
    name = File.basename(application, ".conf")
    apps << name
  end
  apps
end

Facter.add("moonshine") do
  setcode do
    hash = {}
    applications.each do |app|
      hash[app.to_sym] = YAML.load_file("/etc/moonshine/#{app}.conf")
    end
    hash
  end
end