require 'typescript/monkey'

class Typescript::Monkey::Railtie < ::Rails::Railtie
  config.before_initialize do |app|
    if ::Rails::VERSION::MAJOR >= 4 || app.config.assets.enabled
      require 'typescript/monkey/template'
      require 'typescript/monkey/transformer'
      require 'sprockets'

      if Sprockets.respond_to?(:register_engine)
        Sprockets.register_engine '.ts', Typescript::Monkey::Template, silence_deprecation: true
      end

      if Sprockets.respond_to?(:register_transformer)
        Sprockets.register_mime_type 'text/typescript', extensions: ['.ts']
        Sprockets.register_transformer 'text/typescript', 'application/javascript', Typescript::Monkey::Transformer
      end
    end
  end
end
