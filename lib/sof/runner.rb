module Sof
class Runner

  attr_accessor :server_concurrency, :check_concurrency, :manifest, :results

  def initialize(manifest)
    @server_concurrency ||= 10
    @check_concurrency ||= 5
    @manifest = manifest
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
    @results = Parallel.map_with_index(servers, :in_processes => server_concurrency, :progress => 'Running checks') do |server|
      checks = Sof::Check.load(server.categories)
      check_results = Parallel.map_with_index(checks, :in_threads => check_concurrency) do |check|
        { :check => check, :return => check.run(server) }
      end
      { :server => server, :result => check_results }
    end
  end

  def output_results(verbose = false)
    munged_output = {}
    @results.each do |single_result|
      check_results = []
      check_results << "#{single_result[:result].size} checks completed"
      single_result[:result].each do |check_result|
        if check_result[:return].first[1]['status'] == :fail || verbose
          check_results << check_result[:return]
        end
      end
      munged_output[single_result[:server].hostname] = check_results
    end
    puts munged_output.to_yaml
  end
end
end
