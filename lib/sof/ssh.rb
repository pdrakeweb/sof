module Sof
class Ssh

  attr_accessor :server, :ssh_options, :ssh_retries

  NETWORK_EXCEPTIONS = [ Errno::EHOSTUNREACH, Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::ECONNABORTED, Errno::ECONNRESET, Errno::EHOSTUNREACH, Errno::EPIPE, Errno::EINVAL, Timeout::Error, SocketError, EOFError, IOError ]

  def initialize(server)
    @server = server
    @ssh_options = { :port => server.port }
    @ssh_retries = 10
  end

  def exec(cmd)
    output = ''
    errors = ''
    errmsg = ''
    result_code = 0

    remote_command = cmd

    puts "ssh #{@server.username}@#{@server.hostname} #{remote_command}"

    channel = ssh_session.open_channel do |ch|
      ch.exec(remote_command) do |ch2, success|
        fail ExecError, "Remote command could not be started on #{hostname}: #{remote_command}" unless success

        ch2.on_data do |ch3, data|
          output << data
        end

        ch2.on_extended_data do |ch3, type, data|
          errors << data
        end

        ch2.on_request "exit-status" do |ch3, data|
          result_code = data.read_long
          errmsg = "Command returned exit code #{result_code}: #{remote_command}"
        end

        ch2.on_request "exit-signal" do |ch3, data|
          signal = data.read_string
          errmsg = "Command was terminated with signal #{signal}: #{remote_command}"
        end
      end
    end

    channel.wait
    return {:exitstatus => result_code, :stdout => output, :stderr => errors}
  end

  # Return the SSH session used by this object.
  def ssh_session
    begin
      connection_attempts = 0
      begin
        connection_attempts += 1
        @ssh_session = Net::SSH.start(server.hostname, server.username, ssh_options)
      rescue *(NETWORK_EXCEPTIONS) => e
        if connection_attempts >= @ssh_retries
          raise e
        else
          sleep 1
          retry
        end
      end
    rescue => e
      e2 = e.class.new("#{e.message} (#{@username}@#{@hostname}:22})")
      e2.set_backtrace(e.backtrace)
      raise e2
    end
  end

end
end