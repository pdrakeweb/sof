require 'syslog'
require 'benchmark'

# Load these early to work around core ruby bug when threading.
require 'net/ssh'
require 'net/scp'
require 'colorize'

module Sof
  class Runner

    attr_accessor :server_concurrency, :check_concurrency, :manifest, :results, :munged_output, :pass_results,
                  :unhealthy_server_count, :failure_results, :pids

    def initialize(manifest)
      @manifest = manifest
      @options = Sof::Options.instance

      @munged_output = munged_output
      @pass_results = pass_results
      @unhealthy_server_count = unhealthy_server_count
      @failure_results = failure_results
      @pids = []
    end

    def servers
      manifest['servers'].map do |server_record|
        server_record['username'] ||= manifest['username']
        server_record['port'] ||= manifest['port']
        server_record['keys'] ||= manifest['keys']
        Sof::Server.new(server_record)
      end
    end

    def run_checks(progress = 'Running checks')
      @results = []
      @total_time = Benchmark.realtime do
        @results = Parallel.map_with_index(servers, :in_processes => @options.server_concurrency, :progress => progress) do |server|
          @pids << Process.pid
          checks = Sof::Check.load(server.categories, include_base: @options.include_base)
          check_results = []

          # Process the SSH check first if that is one of the checks to run.  Remove all dependent checks if it fails.
          if ssh_check = checks.find { |check| check.name == 'ssh' }
            checks.delete(ssh_check)

            ssh_check_result = { :check => ssh_check, :return => ssh_check.run_check(server) } if ssh_check
            check_results << ssh_check_result

            if ssh_check_result[:return].first[1]['status'] != :pass
              checks.select! { |check| check.dependencies.nil? || !check.dependencies.include?('ssh') }
            end
          end

          check_results += Parallel.map_with_index(checks, :in_threads => @options.check_concurrency) do |check|
            {:check => check, :return => check.run_check(server)}
          end

          @pids.delete Process.pid

          {:server => server, :result => check_results}
        end
      end
    end

    def has_failures?
      !@failure_results.empty?
    end

    def output_results(jira_format, _verbose = false)
      store_results! jira_format

      @failure_results.each do |result|
        puts result[0].colorize(:red)
        puts result[1] if result[1]
        puts result[2] if result[2]
        puts '{noformat}' if jira_format
      end

      @pass_results.each { |result| puts result[0].colorize(:green) } if @options.verbose

      puts @munged_output.to_yaml.colorize(@unhealthy_server_count ? :red : :green)
    end

    def store_results!(jira_format = false)
      munged_output = {}
      server_count = unhealthy_server_count = failure_count = check_count = 0
      pass_results = []
      failure_results = []
      @results.each do |single_result|
        server_has_failure = false

        if single_result[:server].hostname.nil?
          STDERR.puts "WARNING: the hostname in a sof result was nil."
          STDERR.puts single_result
          single_result[:server].hostname = 'UNKNOWN'
        end
        single_result[:result].each do |check_result|
          check_count += 1
          failure = check_result[:return].first[1]['status'] != :pass
          jira_header = '{noformat:title='
          check_string = "#{check_result[:return].first[0].ljust(20)} \
          on #{single_result[:server].hostname.ljust(40)} \
          #{check_result[:return].first[1]['status']}"

          result_string = jira_format ? jira_header + check_string + '}' : check_string
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

      @munged_output = munged_output
      @pass_results = pass_results.sort { |a, b| a[0] <=> b[0] }
      @unhealthy_server_count = unhealthy_server_count
      @failure_results = failure_results.sort { |a, b| a.first <=> b.first }
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
