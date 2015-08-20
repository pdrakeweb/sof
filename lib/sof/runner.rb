require 'sof/check'
require 'sof/server'
require 'sof/checks'

module Sof
class Runner

  attr_accessor :server_concurrency, :check_concurrency

  def initialize
    server_concurrency ||= 0
    check_concurrency ||= 0
  end

  def servers
    (1..2).map{ Sof::Server.new }
  end

  def run_checks
    @results = []
    #Parallel.map_with_index(servers, :in_processes => server_concurrency, :progress => 'Running checks') do |server|
    #result = Parallel.map_with_index(servers, :in_processes => server_concurrency) do |server|
    result = servers.map do |server|
      checks = Sof::Check.load(server.types)
      #result = Parallel.map_with_index(checks, :in_threads => check_concurrency) do |check|
      result = checks.map do |check|
        check.run(server)
      end
    end
    
    pp result
  end

end
end
