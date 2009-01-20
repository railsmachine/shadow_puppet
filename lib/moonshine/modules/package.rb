module MoonshinePackage
  def package(array_or_name, params = {})
    recipe :moonshine_packages, { :packages => array_or_name, :params => params }
    send(:include, InstanceMethods)
  end
  alias_method :packages, :package

  module InstanceMethods
    def moonshine_packages(options = {})
      array_or_name = options[:packages]
      params = options[:params]
      package_array = array_or_name.to_a
      params = {
        :ensure => 'installed'
      }.merge(params)

      package_array.each_with_index do |name,index|
        #provide order
        package_params = params
        if package_array[index+1]
          package_params.merge({
            :before => package(package_array[index+1])
          })
        end
        package name.to_s, package_params
      end
    end
  end

end
Moonshine::Manifest.send(:extend, MoonshinePackage)