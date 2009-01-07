class ServiceManifest < Moonshine::Manifest
  service("foo", %w(curl wget))
end