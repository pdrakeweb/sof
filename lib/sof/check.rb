require 'yaml'

module Sof
  class Check
    CHECK_PATHS = [ File.join(File.dirname(__FILE__), '..', '..', 'checks'), '/opt/sof/checks', "#{Dir.home}/.sof" ]

    attr_accessor :type, :name, :category, :expected_result, :timeout, :command, :sanity, :description, :options, :dependencies, :timeout

    def initialize(check)
      @type = check['type']
      @name = check['name']
      @command = check['command']
      @dependencies = check['dependencies']
      @timeout = check['timeout'] || 30
      @description = check['description']
    end

    def run_check(server)
      check_result = nil
      begin
        Timeout::timeout(@timeout) {
          check_result = run(server)
        }
      rescue Timeout::Error
        check_result = check_timeout_result
      end
      check_result.first[1]['description'] = @description if @description
      check_result
    end

    def check_timeout_result
      { "#{@name} timed out" => {'status' => :timeout } }
    end

    def self.load(category, options)
      records = {}
      objects = []
      CHECK_PATHS.each do |dir_path|
        Dir.glob("#{dir_path}/*.yml") do |yaml_file|
          data = YAML.load_file(yaml_file)
          records[data['name']] = data if data['category'].include?('base') || (category && data['category'].include?(category))
        end
      end

      records.each do |_, record|
        klass = Sof::Checks.class_from_type(record['type'])
        objects << klass.new(record)
        puts record if options[:debug]
      end
      objects
    end
  end
end
