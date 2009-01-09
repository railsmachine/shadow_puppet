class MoonshineUpdateManifest < Moonshine::Manifest
  def update_application(name, option)
    uri = options[:uri]
    user = options[:user]
    branch = options[:branch]
    path = "/var/lib/moonshine/applications/#{name}"
    role "#{name}-moonshine-update" do
      exec "#{name}-moonshine-clone-repo",
        :cwd          => "/var/lib/moonshine/applications/",
        :command      => "/usr/bin/git clone #{uri} && /usr/bin/git checkout -b #{branch}",
        :creates      => path,
        :user         => user,
        :unless       => "/usr/bin/test -d #{path}",
        :before       => [
          exec("#{name}-moonshine-checkout-#{branch}"),
          exec("#{name}-moonshine-update-repo")
        ]

      exec "#{name}-moonshine-checkout-#{branch}",
        :cwd          => path,
        :command      => "/usr/bin/git checkout #{branch}",
        :user         => user,
        :onlyif       => "/usr/bin/test -d #{path}",
        :before       => exec("#{name}-moonshine-update-repo")

      exec "#{name}-moonshine-update-repo",
        :cwd          => path,
        :command      => "/usr/bin/git pull origin #{branch}",
        :user         => user
    end
  end
end