# ShadowPuppet

ShadowPuppet is a Ruby DSL for Puppet, extracted out of the work we at Rails
Machine are doing on [Moonshine](http://blog.railsmachine.com/articles/2009/01/16/moonshine-configuration-management-and-deployment/).

ShadowPuppet provides a DSL for creating collections ("manifests") of Puppet
Resources in Ruby. For documentation on writing these manifests, please see
ShadowPuppet::Manifest.

A [binary](http://railsmachine.github.com/shadow_puppet/files/bin/shadow_puppet.html) is provided to parse and execute a
ShadowPuppet::Manifest.

## Running the Test Suite

First time:

    $ gem install bundler
    $ bundle install
    $ bundle exec rake appraisal:install

Run against all versions of activesupport:

    $ bundle exec rake appraisal spec


Run against a specific one, ie 3.2:

    $ bundle exec rake appraisal:3.2 spec


***

All content copyright &copy; 2014, [Rails Machine, LLC](http://railsmachine.com)
