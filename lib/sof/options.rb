require 'net/ssh'
require 'singleton'

module Sof
class Options
  include Singleton

  @@options = {}

  def self.set_options(options)
    @@options = options
  end

  def method_missing(name, *args, &block)
    @@options[name.to_sym]
  end
end
end
