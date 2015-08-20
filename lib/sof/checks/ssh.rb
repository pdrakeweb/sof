require 'sof/ssh'

module Sof::Checks
class Ssh < Sof::Check

  attr_accessor :sudo

  def initialize(check)
    super(check)
    @sudo = check['sudo']
  end

  def run(server)
    ssh = Sof::Ssh.new(server)
    ssh.exec(@command)
  end

end
end
