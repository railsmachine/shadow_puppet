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

      package "rubygems", :ensure => "installed"
      package "rake", :ensure => "installed"

      package "rubygems-update",
        :ensure   => "installed",
        :provider => "gem",
        :require  => package("rubygems")

      exec "update-rubygems",
        :command      => "/usr/bin/update_rubygems",
        :refreshonly  => true,
        :onlyif       => "/usr/bin/test -f /usr/bin/update_rubygems,"
        :subscribe    => package("rubygems-update"),
        :before       => package('moonshine')

      exec "update-rubygems-var-lib",
        :command      => "/var/lib/gems/1.8/bin/update_rubygems",
        :refreshonly  => true,
        :onlyif       => "/usr/bin/test -f /var/lib/gems/1.8/bin/update_rubygems",
        :subscribe    => package("rubygems-update"),
        :before       => package('moonshine')

      package "moonshine",
        :ensure   => "installed",
        :provider => "gem",
        :require  => [
          package("rake")
        ]
    end
    self.gems_role_defined = true
  end

end
Moonshine::Manifest.send(:extend, MoonshineGem)