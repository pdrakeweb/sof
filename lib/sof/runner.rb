require 'syslog'
require 'benchmark'

# Load these early to work around core ruby bug when threading.
require 'net/ssh'
require 'net/scp'
require 'colorize'

String.disable_colorization true unless $stdout.tty?

module Sof
class Runner

  attr_accessor :server_concurrency, :check_concurrency, :manifest, :results

  def initialize(manifest)
    @manifest = manifest
    @options = Sof::Options.instance
  end

  def servers
    manifest['servers'].map do |server_record|
      server_record['username'] ||= manifest['username']
      server_record['port'] ||= manifest['port']
      Sof::Server.new(server_record)
    end
  end

  def run_checks
    @results = []
    @total_time = Benchmark.realtime do
      @results = Parallel.map_with_index(servers, :in_processes => @options.server_concurrency, :progress => 'Running checks') do |server|
        checks = Sof::Check.load(server.categories)
        check_results = []

        ssh_check = checks.find{ |check| check.name == 'ssh' }
        checks.delete(ssh_check)

        ssh_check_result = { :check => ssh_check, :return => ssh_check.run_check(server) }
        check_results << ssh_check_result

        if ssh_check_result[:return].first[1]['status'] != :pass
          checks.select!{ |check| check.dependencies.nil? || !check.dependencies.include?('ssh') }
        end

        check_results += Parallel.map_with_index(checks, :in_threads => @options.check_concurrency) do |check|
          { :check => check, :return => check.run_check(server) }
        end
        { :server => server, :result => check_results }
      end
    end
  end

  def output_results(jira_format, verbose = false)
    munged_output = {}
    server_count = unhealthy_server_count = failure_count = check_count = 0
    pass_results = []
    failure_results = []
    @results.each do |single_result|
      server_has_failure = false

      single_result[:result].each do |check_result|
        check_count += 1
        failure = check_result[:return].first[1]['status'] != :pass
        jira_header = "{noformat:title="
        check_string = "#{check_result[:return].first[0].ljust(20)} \
          on #{single_result[:server].hostname.ljust(40)} \
          #{check_result[:return].first[1]['status']}"

        result_string = jira_format ? jira_header + check_string + "}" : check_string
        if failure
          failure_count += 1
          server_has_failure = true
          failure_content = [result_string]
          failure_content << multiline_indent(check_result[:return].first[1]['output'].strip) if check_result[:return].first[1]['output']
          failure_content << multiline_indent(check_result[:return].first[1]['description'].strip) if check_result[:return].first[1]['description']
          failure_results << failure_content
        else
          pass_results << [check_string]
        end
      end

      server_count += 1
      unhealthy_server_count += 1 if server_has_failure
    end

    failure_results.sort!{ |a,b| a.first <=> b.first }
    failure_results.each do |result|
      puts result[0].colorize(:red)
      puts result[1] if result[1]
      puts result[2] if result[2]
      puts "{noformat}" if jira_format
    end

    if @options.verbose
      pass_results.sort!{ |a,b| a[0] <=> b[0] }
      pass_results.each do |result|
        puts result[0].colorize(:green)
      end
    end

    munged_output['stats'] = {
      'servers' => {
        'total' => server_count,
        'unhealthy' => unhealthy_server_count,
      },
      'checks' => {
        'total' => check_count,
        'failures' => failure_count,
      },
      'time' => "#{@total_time.round}s",
    }

    if unhealthy_server_count == 0
      puts munged_output.to_yaml.colorize(:green)
    else
      puts munged_output.to_yaml.colorize(:red)
    end
  end

  def multiline_indent(input_string)
    result = ''
    input_string.each_line do |line|
      result << "    #{line}"
    end
    result
  end

  def log_results
    Syslog.open('sof', Syslog::LOG_CONS) do |s|
      @results.each do |single_result|
        server = single_result[:server]
        single_result[:result].each do |check_result|
          result_return = check_result[:return].first[1]
          if result_return['status'] != :pass
            s.err(format_log_message(server, check_result[:check], result_return))
          end
        end
      end
    end
  end

  def format_log_message(server, check, result)
    output = result['output'].nil? ? '-' : result['output'].strip
    "sof #{server.hostname} #{check.name} #{result['status']} #{output}"
  end
end
end
