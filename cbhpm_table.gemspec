# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cbhpm_table/version'

Gem::Specification.new do |spec|
  spec.name          = "cbhpm_table"
  spec.version       = CBHPMTable::VERSION
  spec.authors       = ["Abinoam Praxedes Marques Jr."]
  spec.email         = ["abinoam@gmail.com"]
  spec.summary       = %q{CBHPM Table. A simple wrapper around the CBHPM excel files.}
  spec.description   = %q{It takes a CBHPM Excel spreadsheet file and give convenience methods to deal with it. }
  spec.homepage      = "https://github.com/abinoam/cbhpm_table"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
