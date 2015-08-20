require 'sof'
require 'yaml'

module Sof
class Check

  CHECK_PATHS = [ File.join(File.dirname(__FILE__), '..', 'checks'), '/opt/sof/checks', '~/.sof' ]

  attr_accessor :type, :name, :category, :expected_result, :timeout, :command, :sanity, :description

  def initialize(check)
    @type = check['type']
    @name = check['name']
    @command = check['command']
  end

  def self.create(check)  
    klass = Sof::Checks.class_from_type(check['type'])
    klass.new(check)
  end

  def self.load(types)
    check = YAML.load_file(File.expand_path('../../../checks/load.yml', __FILE__))
    (1..2).map{ Sof::Check.create(check) }
  end

end
end
