# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'waterfoul/version'

Gem::Specification.new do |spec|
  spec.name          = "waterfoul"
  spec.version       = Waterfoul::VERSION
  spec.authors       = ["Colby Swandale"]
  spec.email         = ["me@colby.fyi"]

  spec.summary       = "Gameboy emulator written in Ruby-lang"
  spec.description   = ""
  spec.homepage      = "https://github.com/colby-swandale/waterfoul"


  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor"
  spec.add_dependency "ffi"
end
