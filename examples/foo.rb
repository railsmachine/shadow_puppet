class Foo < ShadowPuppet::Manifest
  recipe :foo

  def foo
    exec :foo, :command => '/bin/echo "foo" > /tmp/foo.txt'
  end
end
