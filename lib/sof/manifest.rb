require 'yaml'

module Sof
  class Manifest
    def self.get(path)
      fail StandardError, "#{path} is not found" unless File.file?(path)

      manifest = YAML.load_file(path)

      fail StandardError, 'Either no port found or bad format in manifest' unless manifest.has_key?('port')
      fail StandardError, 'Either no servers found or bad format in manifest' unless manifest.has_key?('servers')

      manifest['servers'].each do |server|
        fail StandardError, 'Either no name found or bad format in servers in manifest' unless server.has_key?('name')
      end
      manifest
    end
  end
end
