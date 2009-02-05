class Foo < ShadowPuppet::Manifest
  recipe :demo, :text => 'foo'
  recipe :some_gems

  def some_gems
    package 'rails', :ensure => :updated, :provider => :gem
    package 'railsmachine', :ensure => '1.0.5', :provider => :gem, :require => package('capistrano')
    package 'capistrano', :ensure => :updated, :provider => :gem
  end

  def demo(options = {})
    exec 'sample', :command => "echo '#{options[:text]}' > /tmp/sample.txt"
    file '/tmp/sample2.txt', :ensure => :present, :content => Facter.to_hash.inspect
  end
end