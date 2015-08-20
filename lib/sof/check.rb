require 'yaml'

module Sof
  class Check
    CHECK_PATHS = [ File.join(File.dirname(__FILE__), '..', '..', 'checks'), '/opt/sof/checks', '~/.sof' ]

    attr_accessor :type, :name, :category, :expected_result, :timeout, :command, :sanity, :description, :options

    def initialize(check)
      @type = check['type']
      @name = check['name']
      @command = check['command']
    end

    def self.load(category)
      records = {}
      objects = []
      CHECK_PATHS.each do |dir_path|
        Dir.glob("#{dir_path}/*.yml") do |yaml_file|
          data = YAML.load_file(yaml_file)
          records[data['name']] = data if data['category'].include?('base') || !(category & data['category']).empty?
        end
      end

      records.each do |_, record|
        klass = Sof::Checks.class_from_type(record['type'])
        objects << klass.new(record)
      end
      objects
    end
  end
end
