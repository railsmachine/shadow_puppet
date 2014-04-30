require 'shadow_puppet/core_ext'
require 'shadow_puppet/version'

# Silence puppet's dependencies warnings like:
#   racc/parser.rb:27: warning: already initialized constant Racc_Runtime_Version
#   racc/parser.rb:28: warning: already initialized constant Racc_Runtime_Revision
#   racc/parser.rb:30: warning: already initialized constant Racc_Runtime_Core_Version_R
#   racc/parser.rb:31: warning: already initialized constant Racc_Runtime_Core_Revision_R
#   racc/parser.rb:35: warning: already initialized constant Racc_Runtime_Core_Revision_C
#   racc/parser.rb:39: warning: already initialized constant Racc_Main_Parsing_Routine
#   racc/parser.rb:40: warning: already initialized constant Racc_YY_Parse_Method
#   racc/parser.rb:41: warning: already initialized constant Racc_Runtime_Core_Version
#   racc/parser.rb:42: warning: already initialized constant Racc_Runtime_Core_Revision
#   racc/parser.rb:43: warning: already initialized constant Racc_Runtime_Type
#   /usr/lib/ruby/gems/1.9.1/gems/puppet-2.7.3/lib/puppet/type/tidy.rb:102: warning: class variable access from toplevel
#   /usr/lib/ruby/gems/1.9.1/gems/puppet-2.7.3/lib/puppet/type/tidy.rb:107: warning: class variable access from toplevel
#   /usr/lib/ruby/gems/1.9.1/gems/puppet-2.7.3/lib/puppet/type/tidy.rb:107: warning: class variable access from toplevel
#   /usr/lib/ruby/gems/1.9.1/gems/puppet-2.7.3/lib/puppet/type/tidy.rb:108: warning: class variable access from toplevel
#   /usr/lib/ruby/gems/1.9.1/gems/puppet-2.7.3/lib/puppet/type/tidy.rb:108: warning: class variable access from toplevel
#   /usr/lib/ruby/gems/1.9.1/gems/puppet-2.7.3/lib/puppet/type/tidy.rb:109: warning: class variable access from toplevel
#   /usr/lib/ruby/gems/1.9.1/gems/puppet-2.7.3/lib/puppet/type/tidy.rb:109: warning: class variable access from toplevel
#   /usr/lib/ruby/gems/1.9.1/gems/puppet-2.7.3/lib/puppet/type/tidy.rb:149: warning: class variable access from toplevel
#   /usr/lib/ruby/gems/1.9.1/gems/puppet-2.7.3/lib/puppet/provider/service/freebsd.rb:8: warning: class variable access from toplevel
#   /usr/lib/ruby/gems/1.9.1/gems/puppet-2.7.3/lib/puppet/provider/service/freebsd.rb:9: warning: class variable access from toplevel
#   /usr/lib/ruby/gems/1.9.1/gems/puppet-2.7.3/lib/puppet/provider/service/freebsd.rb:10: warning: class variable access from toplevel
#   /usr/lib/ruby/gems/1.9.1/gems/puppet-2.7.3/lib/puppet/provider/service/bsd.rb:11: warning: class variable access from toplevel
#   NOTE: Gem.source_index is deprecated, use Specification. It will be removed on or after 2011-11-01.
#   Gem.source_index called from /srv/app/current/vendor/plugins/moonshine/lib/moonshine/manifest/rails/rails.rb:223.
#   NOTE: Gem::SourceIndex#search is deprecated with no replacement. It will be removed on or after 2011-11-01.
#   Gem::SourceIndex#search called from /srv/app/current/vendor/plugins/moonshine/lib/moonshine/manifest/rails/rails.rb:223
$VERBOSE = nil # comment this out to debug
require 'puppet'
require 'erb'

require 'shadow_puppet/manifest'

class ShadowPuppet::Manifest::Setup < ShadowPuppet::Manifest
  recipe :setup_directories

  def setup_directories()
    if Process.uid == 0
      file "/var/shadow_puppet",
        :ensure => "directory",
        :backup => false
      file "/etc/shadow_puppet",
        :ensure => "directory",
        :backup => false
    else
      file ENV["HOME"] + "/.shadow_puppet",
        :ensure => "directory",
        :backup => false
      file ENV["HOME"] + "/.shadow_puppet/var",
        :ensure   => "directory",
        :backup   => false,
        :require  => file(ENV["HOME"] + "/.shadow_puppet")
    end
  end
end

setup = ShadowPuppet::Manifest::Setup.new
setup.execute
