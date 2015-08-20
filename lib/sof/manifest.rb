require 'yaml'

module Sof
  class Manifest
    def self.get(path)
      fail ManifestError, "#{path} is not found" unless File.file?(path)

      manifest = YAML.load_file(path)

      fail ManifestError, 'Either no port found or bad format in manifest' unless manifest.has_key?('port')
      fail ManifestError, 'Either no servers found or bad format in manifest' unless manifest.has_key?('servers')

      manifest['servers'].each do |server|
        fail ManifestError, 'Either no name found or bad format in servers in manifest' unless server.has_key?('name')
      end
      manifest
    end
  end

  class ManifestError < StandardError
    attr_reader :object
    def initialize(message)
      super(message)
    end
  end
end
