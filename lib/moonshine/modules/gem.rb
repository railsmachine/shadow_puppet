module MoonshineGem
  def gem(array_or_name, params = {})
    recipe :moonshine_gems, { :packages => array_or_name, :params => params }
    send(:include, InstanceMethods)
  end
  alias_method :gems, :gem

  module InstanceMethods
    def moonshine_gems(options = {})
      array_or_name = options[:packages]
      params = options[:params]
      params = {
        :ensure => 'installed'
      }.merge(params)
      moonshine_rubygems

      array_or_name.to_a.each do |name|
        package name.to_s,
          :ensure   => params[:ensure],
          :provider => "gem",
          :require  => package("moonshine")
      end
    end

    def moonshine_rubygems
      package "moonshine",
        :ensure   => "installed",
        :provider => "gem",
        :require  => [
          exec("install-ruby")
        ]
    end
  end
end
Moonshine::Manifest.send(:extend, MoonshineGem)