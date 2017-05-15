module Typescript::Monkey
  require 'pathname'

  #
  # The Transpiler class.
  #
  # A class that implements an interface to a dynamic runtime Typescript to
  # javascript transpiler.
  #
  # The scripts that are returned by this class are dependent upon Typescript
  # Services to be available.
  #
  # @see Typescript::Monkey::Package.services_js
  #
  class Transpiler

    # Returns path to dynamic runtime transpiler
    #
    # The transpiler can be included with web content to transform embedded
    # Typescript wrapped in <script type="text/typescript"></script> tags.
    #
    # @return [Pathname] path to dyrt source
    #
    def self.dyrt_js_path
      transpiler_js_path = gem_javascripts_path()

      if transpiler_js_path
        transpiler_js_path = transpiler_js_path.join("dyrt.js")
        unless transpiler_js_path.file? && transpiler_js_path.readable?
          transpiler_js_path = nil
        end
      end

      transpiler_js_path
    end

    # Returns content for dynamic runtime transpiler
    #
    # The transpiler can be included with web content to transform embedded
    # Typescript wrapped in <script type="text/typescript"></script> tags.
    #
    # @return [String] dyrt source
    #
    def self.dyrt_js
      transpiler_js = ""
      transpiler_js_path = self.dyrt_js_path()

      unless transpiler_js_path.nil?
        transpiler_js = transpiler_js_path.read()
      end

      transpiler_js
    end

    # Returns path to dynamic runtime transpiler
    #
    # The transpiler can be included with web content to transform embedded
    # Typescript wrapped in <script type="text/typescript"></script> tags.
    #
    # The "once" compilers include an immediately invoked function expression
    # (IIFE) that triggers transpile exactly once. Add this script to the
    # bottom of the body in an HTML page; ideally, this should run last. The
    # script does not, and probably should not, be run after DOM ready; however
    # the Typescript objects in your page can wait for DOM ready.
    #
    # @return [Pathname] path to dyrt source
    #
    def self.dyrt_once_js_path
      transpiler_js_path = gem_javascripts_path()

      if transpiler_js_path
        transpiler_js_path = transpiler_js_path.join("dyrt_once.js")
        unless transpiler_js_path.file? && transpiler_js_path.readable?
          transpiler_js_path = nil
        end
      end

      transpiler_js_path
    end

    # Returns content for dynamic runtime transpiler
    #
    # The transpiler can be included with web content to transform embedded
    # Typescript wrapped in <script type="text/typescript"></script> tags.
    #
    # The "once" compilers include an immediately invoked function expression
    # (IIFE) that triggers transpile exactly once. Add this script to the
    # bottom of the body in an HTML page; ideally, this should run last. The
    # script does not, and probably should not, be run after DOM ready; however
    # the Typescript objects in your page can wait for DOM ready.
    #
    # @return [String] dyrt source
    #
    def self.dyrt_once_js
      transpiler_js = ""
      transpiler_js_path = self.dyrt_once_js_path()

      unless transpiler_js_path.nil?
        transpiler_js = transpiler_js_path.read()
      end

      transpiler_js
    end

    # Returns path to dynamic runtime transpiler (pre-transpiled version)
    #
    # The transpiler can be included with web content to transform embedded
    # Typescript wrapped in <script type="text/typescript"></script> tags.
    #
    # @return [Pathname] path to dyrt source (pre-transpiled version)
    #
    def self.dyrt_ts_path
      transpiler_ts_path = gem_typescripts_path()

      if transpiler_ts_path
        transpiler_ts_path = transpiler_ts_path.join("transpiler.ts")
        unless transpiler_ts_path.file? && transpiler_ts_path.readable?
          transpiler_ts_path = nil
        end
      end

      transpiler_ts_path
    end

    # Returns content for dynamic runtime transpiler (pre-transpiled version)
    #
    # The transpiler can be included with web content to transform embedded
    # Typescript wrapped in <script type="text/typescript"></script> tags.
    #
    # @return [String] typescript transpiler source (pre-transpiled version)
    #
    def self.dyrt_ts
      transpiler_ts = ""
      transpiler_ts_path = self.dyrt_ts_path()

      unless transpiler_ts_path.nil?
        transpiler_ts = transpiler_ts_path.read()
      end

      transpiler_ts
    end

    class << self

      # Returns path to transpiler source
      #
      alias runner_js dyrt_js
      alias runner_ts dyrt_ts

      # private

        # Returns path for gem directory
        #
        # The directory is the gem directory to resolve. Must be a value of:
        #   + root          - gem root directory
        #   + lib           - gem lib directory
        #   + assets        - gem lib/assets directory
        #   + javascripts   - gem lib/assets/javascripts directory
        #   + typescripts   - gem lib/assets/typescripts directory
        #
        # Results are memoized.
        #
        # @param directory [String] directory to discover
        #
        # @return [Pathname] path to directory on success, otherwise nil
        #
        # @raise [ArgumentError] raises this exception if directory has not been
        #   supplied or is invalid.
        #
        def gem_path_for(directory)
          if directory.empty? || directory.nil?
            raise ArgumentError, "directory parameter required but not supplied"
          end
          if !["root", "lib", "assets", "javascripts", "typescripts"].include?(directory)
            raise ArgumentError, "invalid directory specified: #{directory}"
          end

          directory_sym = directory.downcase.to_sym
          @gem_paths ||= {}
          return @gem_paths[directory_sym] if @gem_paths.has_key?(directory_sym)

          # resolve gem root (top directory of this gem)
          gem_root = Pathname.new(File.expand_path("../../../../", __FILE__))

          # process shortcuts
          case directory_sym
          when :lib
            gem_path = gem_root.join("lib")
          when :assets
            gem_path = gem_root.join("lib/assets")
          when :javascripts
            gem_path = gem_root.join("lib/assets/javascripts")
          when :typescripts
            gem_path = gem_root.join("lib/assets/typescripts")
          when :root
            gem_path = gem_root
          else
            gem_path = Pathname.new("")
          end

          @gem_paths[directory_sym] = ((gem_path.directory?) ? gem_path : nil)
        end

        # Returns top directory for this gem
        #
        # @return [Pathname] path to directory on success, otherwise nil
        #
        # @see Typescript::Monkey::Transpiler.gem_path_for
        #
        def gem_root_path
          gem_path_for("root")
        end

        # Returns lib directory for this gem
        #
        # @return [Pathname] path to directory on success, otherwise nil
        #
        # @see Typescript::Monkey::Transpiler.gem_path_for
        #
        def gem_lib_path
          gem_path_for("lib")
        end

        # Returns assets directory for this gem
        #
        # @return [Pathname] path to directory on success, otherwise nil
        #
        # @see Typescript::Monkey::Transpiler.gem_path_for
        #
        def gem_assets_path
          gem_path_for("assets")
        end

        # Returns javascripts directory for this gem
        #
        # @return [Pathname] path to directory on success, otherwise nil
        #
        # @see Typescript::Monkey::Transpiler.gem_path_for
        #
        def gem_javascripts_path
          gem_path_for("javascripts")
        end

        # Returns typescripts directory for this gem
        #
        # @return [Pathname] path to directory on success, otherwise nil
        #
        # @see Typescript::Monkey::Transpiler.gem_path_for
        #
        def gem_typescripts_path
          gem_path_for("typescripts")
        end
    end

  end
end
