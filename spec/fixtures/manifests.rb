class BlankManifest < ShadowPuppet::Manifest
end

#this does nothing
class NoOpManifest < ShadowPuppet::Manifest
  def foo
    exec('foo', :command => '/usr/bin/true')
  end

  def bar
    exec('bar', :command => '/usr/bin/true')
  end
end

#demonstrate the default method of satifying requirements: instance methods
class RequiresMetViaMethods < ShadowPuppet::Manifest
  recipe :foo, :bar

  def foo
    exec('foo', :command => '/usr/bin/true')
  end

  def bar
    exec('bar', :command => '/usr/bin/true')
  end
end

#requirements can also be handled by functions in external modules
class ProvidedViaModules < ShadowPuppet::Manifest
  module FooRecipe
    def foo
      exec('foo', :command => '/usr/bin/true')
    end
  end

  module BarRecipe
    def bar
      exec('bar', :command => '/usr/bin/true')
    end
  end
  include FooRecipe
  include BarRecipe
  recipe :foo, :bar
end

#requirements can also be handled by functions in external modules
class PassingArguments < ShadowPuppet::Manifest
  def foo(options = {})
    exec(options[:name], :command => '/usr/bin/true')
  end
  recipe :foo, :name => 'bar'
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