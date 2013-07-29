lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wresque_wrapper/version'

Gem::Specification.new do |s|
  s.name             = "wresque_wrapper"
  s.version          = WresqueWrapper::VERSION
  s.authors          = ["Simon Coffey"]
  s.date             = "2012-11-26"
  s.description      = "Allows inline queueing of model methods to Resque, e.g. MyModel.delay.some_method, or some_instance.delay(:queue => :bigjobs).another_method"
  s.email            = "simon@urbanautomaton.com"
  s.files            = `git ls-files`.split($/)
  s.homepage         = "http://github.com/urbanautomaton/wresque_wrapper"
  s.licenses         = ["MIT"]
  s.require_paths    = ["lib"]
  s.summary          = "Async-style queueing of class methods using Resque"

  s.add_dependency "resque"
  s.add_dependency "rails"

  s.add_development_dependency "rspec"
  s.add_development_dependency "mocha"
  s.add_development_dependency "bundler"
  s.add_development_dependency "jeweler"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "activesupport"
end

