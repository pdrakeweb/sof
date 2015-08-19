require 'yaml'

module Sof
  class YamlObjectFactory
    def get_objects(dir_paths, object_class)
      records = {}
      objects = []
      dir_paths.each do |dir_path|
        Dir.glob("#{dir_path}*.yml") do |yaml_file|
          data = YAML.load_file(yaml_file)
          records[data['name']] = data
        end
      end
      records.each do |record|
        objects = object_class.new(record)
      end
      objects
    end
  end
end
