class BlankManifest < Moonshine::Manifest
end
class ClassLevelRole < Moonshine::Manifest
  role :debug do
    exec "whoami", :command => "/usr/bin/whoami > /tmp/whoami.txt"
  end
end

#built-in modules
class ServiceManifest < Moonshine::Manifest
  service("foo", %w(curl wget))
end

class UserManifest < Moonshine::Manifest
  user("foo")
end

#this does nothing
class NoOpManifest < Moonshine::Manifest
  def foo
    puppet.exec('/bin/true')
  end

  def bar
    puppet.exec('/bin/true')
  end
end

#demonstrate the default method of satifying requirements: instance methods
class RequiresMetViaMethods < Moonshine::Manifest
  recipe :foo, :bar

  def foo
    puppet.exec('/bin/true')
  end

  def bar
    puppet.exec('/bin/true')
  end
end

#requirements can also be handled by functions in external modules
class ProvidedViaModules < Moonshine::Manifest
  module FooRecipe
    def foo
      puppet.exec('/bin/true')
    end
  end

  module BarRecipe
    def bar
      puppet.exec('/bin/true')
    end
  end
  include FooRecipe
  include BarRecipe
  recipe :foo, :bar
end

#requirements can also be handled by functions in external modules
class OverloadedModules < Moonshine::Manifest
  module WrongFoo
    def foo
      puppet.exec('wrong', :command => '/bin/false')
    end 
  end

  module RightFoo
    def foo
      puppet.exec('right', :command => '/bin/true')
    end
  end
  include RightFoo
  include WrongFoo
  recipe :bar => RightFoo
end

# since self.respond_to?(:foo) == false, this raises an error when run
class RequirementsNotMet < Moonshine::Manifest
  recipe :foo, :bar

  # def foo
  # end

  def bar
    #this is okay
  end
end