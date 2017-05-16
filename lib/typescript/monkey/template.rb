require 'typescript/monkey'
require 'tilt/template'

class Typescript::Monkey::Template < ::Tilt::Template
  self.default_mime_type = 'application/javascript'

  # @!scope class
  class_attribute :default_bare

  def self.engine_initialized?
    defined? ::Typescript::Monkey::Compiler
  end

  def initialize_engine
    require_template_library 'typescript/monkey/compiler'
  end

  def prepare
    if !options.key?(:bare) and !options.key?(:no_wrap)
      options[:bare] = self.class.default_bare
    end
  end

  def evaluate(context, locals, &block)
    @output ||= ::Typescript::Monkey::Compiler.compile(file, data, context)
  end

  # @override
  def allows_script?
    false
  end
end
