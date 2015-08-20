module Sof
class Runner

  attr_accessor :server_concurrency, :check_concurrency, :manifest

  def initialize(manifest)
    @server_concurrency ||= 2
    @check_concurrency ||= 2
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
    #Parallel.map_with_index(servers, :in_processes => server_concurrency, :progress => 'Running checks') do |server|
    result = Parallel.map_with_index(servers, :in_processes => server_concurrency) do |server|
      checks = Sof::Check.load(server.categories)
      puts YAML.dump(server.categories)
      result = Parallel.map_with_index(checks, :in_threads => check_concurrency) do |check|
        check.run(server)
      end
    end
    
    pp result
  end

end
end
