require 'sof'

module Sof
class CheckLoader

  def self.check_paths
    [ File.join(File.dirname(__FILE__), '..', 'checks'), '/opt/sof/checks', '~/.sof' ]
  end
  
  def self.find_checks
    checks = []
    check_paths.each do |check_path|
      Dir.entries(check_path).each do |check_file|
        checks << check_file
      end
    end
    checks
  end

end
end
