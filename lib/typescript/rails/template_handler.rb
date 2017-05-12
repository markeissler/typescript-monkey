require 'typescript/rails/compiler'

class Typescript::Rails::TemplateHandler
  class << self
    def erb_handler
      @erb_handler ||= ActionView::Template.registered_template_handler(:erb)
    end

    def call(template)
      compiled_source = erb_handler.call(template)
      path = template.identifier.gsub(/['\\]/, '\\\\\&') # "'" => "\\'", '\\' => '\\\\'
      <<-EOS
        ::Typescript::Rails::Compiler.compile('#{path}', (begin;#{compiled_source};end))
      EOS
    end
  end
end

# Register template handler for .ts files, enable digest for .ts files
ActiveSupport.on_load(:action_view) do
  ActionView::Template.register_template_handler :ts, Typescript::Rails::TemplateHandler
  require 'action_view/dependency_tracker'
  ActionView::DependencyTracker.register_tracker :ts, ActionView::DependencyTracker::ERBTracker
end
