module Typescript::Rails
  require 'pathname'
  require_relative 'cli'

  #
  # The Package class.
  #
  # A class that implements an interface to the Typescript node installation.
  #
  class Package
    # Returns path to Typescript compiler executable
    #
    # The executable compiler can be used to transform Typescript to Javascript
    # and is used during the asset pipeline compilation stage.
    #
    # @return [Pathname] path to Typescript compiler executable
    #
    def self.compiler_bin_path
      compiler_bin_path = npm_bin_path()

      if compiler_bin_path
        compiler_bin_path = compiler_bin_path.join("tsc")
        unless (compiler_bin_path && compiler_bin_path.file? && compiler_bin_path.executable?)
          compiler_bin_path = nil
        end
      end

      compiler_bin_path
    end

    # @TODO: REMOVE compiler_js_path()
    # Returns path to Typescript compiler source
    #
    # The compiler can be included with web content to transform embedded
    # Typescript wrapped in <script type="text/typescript"></script> tags.
    #
    # @return [Pathname] path to Typescript javascript compiler source
    #
    def self.compiler_js_path
      compiler_js_path = npm_root_path()

      if compiler_js_path
        compiler_js_path = compiler_js_path.join("typescript/lib/typescriptServices.js")
        unless compiler_js_path.file? && compiler_js_path.readable?
          compiler_js_path = nil
        end
      end

      compiler_js_path
    end

    # @TODO: REMOVE compiler_js()
    # Returns content for Typescript compiler source
    #
    # The compiler can be included with web content to transform embedded
    # Typescript wrapped in <script type="text/typescript"></script> tags.
    #
    # @return [String] javascript Typescript compiler source
    #
    def self.compiler_js
      compiler_js = ""
      compiler_js_path = self.compiler_js_path()

      unless compiler_js_path.nil?
        compiler_js = compiler_js_path.read()
      end

      compiler_js
    end

    # Returns package version for Typescript installation
    #
    # @return [String] version information
    #
    def self.compiler_version
      compiler_version = "unknown"
      metadata = self.metadata()

      unless metadata.empty? || !metadata.has_key?('version')
        compiler_version = metadata['version']
      end

      compiler_version
    end

    # Returns path to package metadata file for Typescript installation
    #
    # The package metadata file is the package.json file.
    #
    # @return [Pathname] path to Typepackage information file
    #
    def self.metadata_path
      metadata_path = npm_root_path()

      if metadata_path
        metadata_path = metadata_path.join("typescript/package.json")
        unless metadata_path.file? && metadata_path.readable?
          metadata_path = nil
        end
      end

      metadata_path
    end


    # Returns package metadata contents for Typescript installation
    #
    # @return [Hash] hash representation of package metadata contents
    #
    def self.metadata
      metadata = {}
      metadata_path = self.metadata_path()

      unless metadata_path.nil?
        metadata = JSON.parse(metadata_path.read())
        metadata ||= {}
      end

      metadata
    end

    # Returns path to Typescript services javascript source
    #
    # The Typescript services can be included with web content to provide
    # embedded Typescript functionality. This Typescript::Rails::Transpiler
    # leverages services to transpile <script type="text/typescript"> tags
    # at runtime.
    #
    # @return [Pathname] path to Typescript service javascript source
    #
    def self.services_js_path
      services_js_path = npm_root_path()

      if services_js_path
        services_js_path = services_js_path.join("typescript/lib/typescriptServices.js")
        unless services_js_path.file? && services_js_path.readable?
          services_js_path = nil
        end
      end

      services_js_path
    end

    # Returns content for Typescript services javascript source
    #
    # The Typescript services can be included with web content to provide
    # embedded Typescript functionality. This Typescript::Rails::Transpiler
    # leverages services to transpile <script type="text/typescript"> tags
    # at runtime.
    #
    # @return [String] Typescript services javascript source
    #
    def self.services_js
      services_js = ""
      services_js_path = self.services_js_path()

      unless services_js_path.nil?
        services_js = services_js_path.read()
      end

      services_js
    end

    class << self
      # Returns path to Typescript compiler executable
      #
      alias compiler_bin compiler_bin_path

      private

        # Returns closest path for npm directory
        #
        # The directory is the npm directory to resolve. Must be a value of:
        #   + root      - effective node_modules root directory
        #   + bin       - effective node_modules bin directory
        #
        # The resolution process favors a local node_modules directory over a
        # global installation.
        #
        # @param directory [String] directory to discover
        #
        # @return [Pathname] path to directory on success, otherwise nil
        #
        # @raise [ArgumentError] raises this exception if directory has not been
        #   supplied or is invalid.
        #
        def npm_path_for(directory)
          if directory.empty? || directory.nil?
            raise ArgumentError, "directory parameter required but not supplied"
          end
          if !["bin", "root"].include?(directory)
            raise ArgumentError, "invalid directory specified: #{directory}"
          end

          npm_path, stderr, status = Typescript::Rails::CLI.run_command("npm", [directory])
          unless status.success? && File.directory?(npm_path.chomp!)
            # try again with global resolution
            npm_path, stderr, status = Typescript::Rails::CLI.run_command("npm", ["--global", directory])
            unless status.success? && File.directory?(npm_path.chomp!)
              npm_path = ""
            end
          end

          ((npm_path_obj = Pathname.new(npm_path)).to_s.empty?) ? nil : npm_path_obj
        end

        # Returns closest path for npm root directory
        #
        # The resolution process favors a local node_modules directory over a
        # global installation.
        #
        # Results are memoized.
        #
        # @return [Pathname] path to directory on success, otherwise nil
        #
        # @see Typescript::Rails::Package.npm_path_for
        #
        def npm_root_path
          @npm_root_path ||= npm_path_for("root")
        end

        # Returns closest path for npm bin directory
        #
        # The resolution process favors a local node_modules directory over a
        # global installation.
        #
        # Results are memoized.
        #
        # @return [Pathname] path to directory on success, otherwise nil
        #
        # @see Typescript::Rails::Packags.npm_path_for
        #
        def npm_bin_path
          @npm_bin_path ||= npm_path_for("bin")
        end
    end

  end
end
