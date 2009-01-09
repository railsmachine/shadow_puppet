module MoonshineGem
  mattr_accessor :gems_role_defined

  def gem(array_or_name, params = {})
    params = {
      :ensure => 'installed'
    }.merge(params)
    define_rubygems_role unless self.gems_role_defined

    array_or_name.to_a.each do |name|
      role "gem-#{name}" do
        package name.to_s,
          :ensure   => params[:ensure],
          :provider => "gem",
          :require  => package("moonshine")
      end
    end
  end

  def define_rubygems_role
    role :rubygems do

      package "moonshine",
        :ensure   => "installed",
        :provider => "gem",
        :require  => [
          exec("install-ruby")
        ]
    end
    self.gems_role_defined = true
  end

end
Moonshine::Manifest.send(:extend, MoonshineGem)