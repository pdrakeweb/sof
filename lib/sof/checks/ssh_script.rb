require_relative '../ssh'

module Sof::Checks
class SshScript < Sof::Check

  def initialize(check)
    super(check)
    @sudo = check['sudo']
    @expected_result = check['expected_result'] || 0
    @path = check['path']
    @remote_path = '/tmp'
  end

  def local_path
    if Pathname.new(@path).absolute?
      @path
    else
      File.join(File.dirname(__FILE__), '..', '..', '..', @path)
    end
  end

  def command
     @sudo.nil? ? @command : "sudo -u #{@sudo} #{@remote_path}/#{@command}"
  end

  def run(server)
    ssh = Sof::Ssh.new(server, echo: @options.debug)
    extra_fields = {}
    begin
      ssh.ssh_session.scp.upload!("#{local_path}/#{@command}", @remote_path)
      ssh.exec("chmod +x #{@remote_path}/#{@command}")
      ssh_result = ssh.exec(command)
      ssh.exec("rm #{@remote_path}/#{@command}")

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
