require 'rbconfig'
# ruby 1.8.7 doesn't define RUBY_ENGINE
ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
ruby_version = RbConfig::CONFIG["ruby_version"]
path = File.expand_path('..', __FILE__)
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/diff-lcs-1.2.5/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/net-ssh-2.9.2/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/parallel-1.6.1/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/rspec-support-3.3.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/rspec-core-3.3.2/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/rspec-expectations-3.3.1/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/rspec-mocks-3.3.2/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/rspec-3.3.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/ruby-progressbar-1.7.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/thor-0.19.1/lib"
