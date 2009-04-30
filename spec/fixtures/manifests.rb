class BlankManifest < ShadowPuppet::Manifest
end

#this does nothing
class NoOpManifest < ShadowPuppet::Manifest
  def foo
    exec('foo', :command => 'true')
  end

  def bar
    exec('bar', :command => 'true')
  end
end

#demonstrate the default method of satifying requirements: instance methods
class RequiresMetViaMethods < ShadowPuppet::Manifest
  recipe :foo, :bar

  configure({ :foo => :bar , :nested_hash => { :nested_foo => :bar } })

  def foo
    exec('foo', :command => 'true')
  end

  def bar
    exec('bar', :command => 'true')
  end
end

class RequiresMetViaMethodsSubclass < RequiresMetViaMethods
  recipe :baz

  configure({ :baz => :bar, :nested_hash => { :nested_baz => :bar } })

  def baz
    exec('baz', :command => 'true')
  end
end

#requirements can also be handled by functions in external modules
class ProvidedViaModules < ShadowPuppet::Manifest
  module FooRecipe
    def foo
      file('/tmp/moonshine_foo', :ensure => 'present', :content => 'foo')
    end
  end

  module BarRecipe
    def bar
      file('/tmp/moonshine_bar', :ensure => 'absent')
    end
  end
  include FooRecipe
  include BarRecipe
  recipe :foo, :bar
end

#requirements can also be handled by functions in external modules
class PassingArguments < ShadowPuppet::Manifest
  def foo(options = {})
    file(options[:name], :ensure => 'present', :content => 'foo')
  end
  recipe :foo, :name => '/tmp/moonshine_foo'
end

# since self.respond_to?(:foo) == false, this raises an error when run
class RequirementsNotMet < ShadowPuppet::Manifest
  recipe :foo, :bar

  # def foo
  # end

  def bar
    #this is okay
  end
end

class ConfigurationWithConvention  < ShadowPuppet::Manifest
  configure(:foo => :bar)
  def foo(string)
    file('/tmp/moonshine_foo', :ensure => 'present', :content => string.to_s)
  end
  recipe :foo
end

# setting up a few different resource types to test the test helpers
class TestHelpers < ShadowPuppet::Manifest

  def foo
    exec('foo', :command => 'true',:onlyif => 'test `hostname` == "foo"')
    package('bar',:ensure => :installed)
    file('baz', :content => 'bar',:mode => '644',:owner => 'rails')
  end

end