require_relative '../ssh'

module Sof::Checks
class Ssh < Sof::Check

  def initialize(check)
    super(check)
    @sudo = check['user']
    @expected_result = check['expected_result'] || 0
  end

  def command(server)
    command_template = @sudo.nil? ? @command : "sudo -u #{@sudo} #{@command}"
    renderer = ERB.new(command_template)
    renderer.result(server.get_binding)
  end

  def run(server)
    ssh = Sof::Ssh.new(server, echo: @options.debug)
    extra_fields = {}
    begin
      ssh_result = ssh.exec(command(server))

      case ssh_result[:exitstatus]
      when 255
        check_title = "#{@name} SSH could not connect"
      when 127
        check_title = "#{@name} check not found"
      else
        check_title = "#{@name}"
      end

      stdout = @options.verbose ? ssh_result[:stdout] : truncate(ssh_result[:stdout])
      extra_fields = { 'exit status' => ssh_result[:exitstatus], 'output' => stdout }
      check_status = ssh_result[:exitstatus] ==  @expected_result ? :pass : :fail
    rescue SocketError
      check_title = "#{@name} host unknown or unreachable"
      check_status = :fail
    rescue Errno::ECONNREFUSED
      check_title = "#{@name} connection refused"
      check_status = :fail
    end

    check_result = {'status' => check_status }.merge(extra_fields)
    { check_title =>  check_result }
  end

  def truncate(s, length = 255, ellipsis = '...')
    if s.length > length
      ellipsis + s.reverse[0..length].reverse
    else
      s
    end
  end
end
end
