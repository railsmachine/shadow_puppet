require 'moonshine'
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
    "true"
  end
end

Facter.add("moonshine_applications") do
  setcode do
    applications.join(',')
  end
end

applications.each do |app|
  name = "#{app}_config"
  config = YAML.load_file("/etc/moonshine/#{app}.conf")
  Facter.add(name) do
    setcode do
      config
    end
  end
end