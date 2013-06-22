# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'veewee-to-packer/version'

Gem::Specification.new do |gem|
  gem.name          = "veewee-to-packer"
  gem.version       = VeeweeToPacker::VERSION
  gem.authors       = ["Mitchell Hashimoto"]
  gem.email         = ["mitchell.hashimoto@gmail.com"]
  gem.description   = %q{Converts Veewee templates to Packer templates.}
  gem.summary       = %q{Converts Veewee templates to Packer templates perfectly.}
  gem.homepage      = "https://github.com/mitchellh/veewee-to-packer"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
