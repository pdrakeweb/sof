require_relative '../local_system'
require 'erb'

module Sof::Checks
class Local < Sof::Check

  def initialize(check)
    super(check)
    @sudo = check['sudo']
    @expected_result = check['expected_result'] || 0
  end

  def command(server)
    command_template = @sudo.nil? ? @command : "sudo -u #{@sudo} #{@command}"
    renderer = ERB.new(command_template)
    renderer.result(server.get_binding)
  end

  def run(server)
    local_system = Sof::LocalSystem.new(echo: @options[:debug])
    extra_fields = {}

   local_result = local_system.exec(command(server))

    case local_result[:exitstatus]
    when 127
      check_title = "#{@name} check not found"
    else
      check_title = "#{@name}"
    end

    extra_fields = { 'exit status' => local_result[:exitstatus], 'stdout' => local_result[:stdout].strip }
    check_status = local_result[:exitstatus] ==  @expected_result ? :pass : :fail

    check_result = {'status' => check_status }.merge(extra_fields)
    { check_title =>  check_result }
  end

end
end
