module MoonshinePackage
  def package(array_or_name, params = {})
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
      role "package-#{name}" do
        package name.to_s, package_params
      end
    end
  end
  alias_method :pacakges, :package

end
Moonshine::Manifest.send(:extend, MoonshinePackage)