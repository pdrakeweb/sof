require_relative '../ssh'

module Sof::Checks
class Ssh < Sof::Check

  attr_accessor :sudo

  def initialize(check)
    super(check)
    @sudo = check['sudo']
  end

  def command
    @sudo.nil? ? @command : "sudo -u #{@sudo} #{@command}"
  end

  def run(server)
    ssh = Sof::Ssh.new(server)
    ssh_result = ssh.exec(command)

    case ssh_result[:exitstatus]
    when 255
      check_title = "#{@name} SSH could not connect"
    when 127
      check_title = "#{@name} check not found"
    else
      check_title = "#{@name}"
    end

    check_status = ssh_result[:exitstatus] == 0 ? :pass : :fail
    { check_title => {'status' => check_status, 'exit status' => ssh_result[:exitstatus], 'stdout' => ssh_result[:stdout].strip } }

  end

end
end
