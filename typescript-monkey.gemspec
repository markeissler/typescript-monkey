# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'typescript/monkey'

Gem::Specification.new do |gem|
  gem.name          = 'typescript-monkey'
  gem.version       = Typescript::Monkey::VERSION
  gem.platform      = Gem::Platform::RUBY
  gem.authors       = ['Mark Eissler']
  gem.email         = %w(moe@markeissler.org)
  gem.description   = %q{A TypeScript transpiler engine for the Rails asset pipeline.}
  gem.summary       = %q{Adds TypeScript to JavaScript transpilation support to the Rails Asset pipeline.}
  gem.homepage      = 'https://github.com/markeissler/typescript-monkey'

  gem.add_runtime_dependency 'tilt'
  gem.add_runtime_dependency 'railties'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 2.0.0'
end
