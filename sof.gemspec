name = "sof"
require "./lib/#{name}/version"

Gem::Specification.new name, Sof::VERSION do |s|
  s.summary = "Check the status of a server on fire"
  s.authors = ["William", "Peter", "Shawn", "Tom"]
  s.email = "acquia@acquia.com"
  s.homepage = "https://github.com/pdrakeweb/#{name}"
  s.files = `git ls-files lib LICENSE`.split("\n")
  s.license = "GPL"
  s.required_ruby_version = '>= 1.9.3'
end
