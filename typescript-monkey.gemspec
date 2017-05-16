#
# typescript-monkey.gemspec
#
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'date'
require 'typescript/monkey'

Gem::Specification.new do |spec|
  spec.name          = "typescript-monkey"
  spec.version       = Typescript::Monkey::VERSION
  spec.date          = Date.today.to_s
  spec.platform      = Gem::Platform::RUBY

  spec.authors       = ["Mark Eissler"]
  spec.email         = "moe@markeissler.org"

  spec.summary       = %q{A TypeScript transpiler engine for the Rails asset pipeline.}
  spec.description   = %q{Adds TypeScript to JavaScript transpilation support to the Rails Asset pipeline.}

  spec.homepage      = "https://github.com/markeissler/typescript-monkey"
  spec.license       = "MIT"

  spec.add_runtime_dependency 'tilt', '~> 2.0', '>= 2.0.0'
  spec.add_runtime_dependency 'railties', '>= 4.0.0', '< 5.0.0'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0.0'
end
