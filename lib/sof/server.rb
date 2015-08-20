require 'net/ssh'

module Sof
class Server
  attr_accessor :categories, :hostname, :username, :port

  def initialize(server_record)
    @categories ||= server_record['categories']
    @hostname ||= server_record['name']
    @username ||= server_record['username']
    @port ||= server_record['port']
  end

  def run(check)
    check.run(hostname, port, username)
  end

  def get_binding
    binding()
  end
end
end
