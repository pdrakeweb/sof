require 'syslog'
require 'benchmark'

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

  def output_results(verbose = false)
    munged_output = {}
    server_count = unhealthy_server_count = failure_count = check_count = 0

    @results.each do |single_result|
      check_results = []
      server_has_failure = false
      check_results << "#{single_result[:result].size} checks completed"

      single_result[:result].each do |check_result|
        check_count += 1
        failure = check_result[:return].first[1]['status'] != :pass
        if failure
          failure_count += 1
          server_has_failure = true
        end
        if failure || @options.verbose
          check_results << check_result[:return]
        end
      end

      if server_has_failure || @options.verbose
        munged_output[single_result[:server].hostname] = check_results
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

    puts munged_output.to_yaml
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
