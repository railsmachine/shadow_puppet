class Foo < ShadowPuppet::Manifest
  recipe :foo

  def foo
    exec :foo, :command => '/bin/echo "foo" > /tmp/foo.txt'
    file '/tmp/example.txt', :ensure => :present, :content => Facter.to_hash.inspect
  end
end
