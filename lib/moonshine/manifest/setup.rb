class MoonshineSetupManifest < Moonshine::Manifest
  recipe :moonshine_setup

  def moonshine_setup
    group "moonshine",
      :ensure     => "present",
      :allowdupe  => false

    file "/var/lib",
      :ensure => "directory"

    file "/var/puppet",
      :ensure => "directory"

    file "/etc/moonshine",
      :ensure => "directory"

    file "/var/lib/moonshine",
      :ensure  => "directory",
      :owner   => "root",
      :group   => "moonshine",
      :mode    => "770"

    file "/var/lib/moonshine/applications",
      :ensure  => "directory",
      :owner   => "root",
      :group   => "moonshine",
      :mode    => "770"
  end
end