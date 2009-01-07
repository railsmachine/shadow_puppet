module MoonshineService
  def service(name, packages =[])
    role "#{name}-service" do
      packages.each do |p|
        package p,
          :ensure => "installed",
          :before => service(name)
      end

      service name,
          :ensure          => "running",
          :enable          => true
    end
  end
end
Moonshine::Manifest.send(:extend, MoonshineService)