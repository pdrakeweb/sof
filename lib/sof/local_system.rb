require 'popen4'

module Sof
class LocalSystem

  def initialize(echo:)
    @echo = echo
  end

  def exec(cmd)
    output = ''
    errors = ''

    status = POpen4.popen4(cmd) do |stdout, stderr, stdin, pid|
      # Read from stdout and stderr as data becomes available so the child
      # does not block on a full pipe and we get the data in order.
      rds = { stdout => :stdout, stderr => :stderr }
      while (!rds.empty?)
        ready = IO.select(rds.keys, nil, nil, nil)
        ready[0].each do |io|
          begin
            data = io.readpartial(2048)
            output << data if rds[io] == :stdout
            errors << data if rds[io] == :stderr
          rescue EOFError
            rds.delete(io)
          end
        end
      end
    end

    if @echo
      puts cmd
      puts output
      STDERR.puts errors
    end

    return {:exitstatus => status.exitstatus, :stdout => output, :stderr => errors}
  end

end
end