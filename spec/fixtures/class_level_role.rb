class ClassLevelRole < Moonshine::Manifest
  role :debug do
    exec "whoami", :command => "/usr/bin/whoami > /tmp/whoami.txt"
  end
end