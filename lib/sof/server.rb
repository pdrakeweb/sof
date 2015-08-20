require 'sof'
require 'net/ssh'

module Sof
class Server
  attr_accessor :types, :hostname, :username, :port

  def initialize
    @types ||= [:web]
    @hostname ||= 'localhost'
    @username ||= 'root'
    @port ||= '22'
  end

  def run(check)
    check.run(@hostname, @port, @username)
  end
end
end
