require 'bundler/setup'

begin
  require 'rspec/core/rake_task'
  task :default => ['spec:all']

  namespace 'spec' do
    RSpec::Core::RakeTask.new(:unit) do |t|
      t.rspec_opts = "--tag type:unit --format documentation"
    end

    RSpec::Core::RakeTask.new(:system) do |t|
      t.rspec_opts = "--tag type:system --format documentation"
    end

    RSpec::Core::RakeTask.new(:all)
  end
rescue LoadError
  # No rspec available.  The gem has been installed without development dependencies.
end
