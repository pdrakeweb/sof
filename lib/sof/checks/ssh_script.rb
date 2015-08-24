require_relative '../ssh'

module Sof::Checks
class SshScript < Sof::Check

  # @todo consider where we can write this which is less likely to suffer
  # from disk-full than /tmp.
  REMOTE_PATH = '/tmp'

  def initialize(check)
    super(check)
    @sudo = check['user']
    @expected_result = check['expected_result'] || 0
    @path = check['path']
  end

  def local_path
    if Pathname.new(@path).absolute?
      @path
    else
      File.join(File.dirname(__FILE__), '..', '..', '..', @path)
    end
  end

  def command
     @sudo.nil? ? @command : "sudo -u #{@sudo} #{REMOTE_PATH}/#{@command}"
  end

  def run(server)
    ssh = Sof::Ssh.new(server, echo: @options.debug)
    extra_fields = {}
    check_result = {}
    begin

      # @todo move run_remote_script to Sof::Server.
      ssh_result = run_remote_script(ssh)

      case ssh_result[:exitstatus]
      when 255
        check_title = "#{@name} SSH could not connect"
      when 127
        check_title = "#{@name} check not found"
      else
        check_title = "#{@name}"
      end
      stdout = @options.verbose ? ssh_result[:stdout] : truncate(ssh_result[:stdout])
      check_result = {
        'status' => ssh_result[:exitstatus] ==  @expected_result ? :pass : :fail,
        'exit status' => ssh_result[:exitstatus],
        'output' => stdout,
      }
    rescue SocketError
      check_title = "#{@name}"
      check_result = {
        'status' => :error,
        'output' => 'host unknown or unreachable',
      }
    rescue Errno::ECONNREFUSED
      check_title = "#{@name}"
      check_result = {
        'status' => :error,
        'output' => 'connection refused',
      }
    rescue RuntimeError => e
      if e.message.match(/No space left on device/)
        check_title = "#{@name}"
        check_result = {
          'status' => :error,
          'output' => 'disk full',
        }
      else
        raise e
      end
    end

    { check_title =>  check_result }
  end

  def run_remote_script(ssh)
    ssh.ssh_session.scp.upload!("#{local_path}/#{@command}", REMOTE_PATH)
    ssh.exec("chmod +x #{REMOTE_PATH}/#{@command}")
    ssh_result = ssh.exec(command)
    begin
      ssh.exec("rm #{REMOTE_PATH}/#{@command}")
    rescue => e
      # This space left intentionally blank.
      # @todo should we do something more here?
    end
    ssh_result
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
