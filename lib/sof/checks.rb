require 'sof/checks/ssh'

module Sof::Checks
  UnknownCheckType = Class.new(RuntimeError)

  def self.class_from_type(type)
    Sof::Checks.const_get(camelize(type))
  rescue NameError
    raise(UnknownCheckType, "Unknown check type #{type}")
  end
  
  def self.camelize(type)
    type.split("_").each {|s| s.capitalize! }.join("")
  end
end
