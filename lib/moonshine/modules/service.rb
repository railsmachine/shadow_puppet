module MoonshineService
  def service(name, packages =[])
    recipe :moonshine_service, { :name => name, :packages => packages }
    send(:include, InstanceMethods)
  end

  module InstanceMethods
    def moonshine_service(options = {})
      options = {:packages => [], :name => nil}.merge(options)
      return if options[:name].nil?
      options[:packages].each do |p|
        package p,
          :ensure => "installed",
          :before => service(options[:name])
      end

      service options[:name],
        :ensure          => "running",
        :enable          => true
    end
  end

end
Moonshine::Manifest.send(:extend, MoonshineService)