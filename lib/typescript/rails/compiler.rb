require 'typescript/rails'
require 'typescript/rails/configuration'
require 'open3'

module Typescript::Rails::Compiler
  class TypescriptCompileError < RuntimeError; end

  class << self
    attr_accessor :configuration
    attr_accessor :default_options
    attr_accessor :logger

    # Replace relative paths specified in /// <reference path="..." /> with absolute paths.
    #
    # @param [String] ts_path Source .ts path
    # @param [String] source. It might be pre-processed by erb.
    # @return [String] replaces source
    #
    def replace_relative_references(ts_path, source)
      ts_dir = File.dirname(File.expand_path(ts_path))
      escaped_dir = ts_dir.gsub(/["\\]/, '\\\\\&') # "\"" => "\\\"", '\\' => '\\\\'

      # Why don't we just use gsub? Because it display odd behavior with File.join on Ruby 2.0
      # So we go the long way around.
      (source.each_line.map do |l|
        if l.starts_with?('///') && !(m = %r!^///\s*<reference\s+path=(?:"([^"]+)"|'([^']+)')\s*/>\s*!.match(l)).nil?
          matched_path = m.captures.compact[0]
          l = l.sub(matched_path, File.join(escaped_dir, matched_path))
        end
        next l
      end).join
    end

    # Get all references
    #
    # @param [String] path Source .ts path
    # @param [String] source. It might be pre-processed by erb.
    # @yieldreturn [String] matched ref abs_path
    #
    def get_all_reference_paths(path, source, visited_paths=Set.new, &block)
      visited_paths << path
      source ||= File.read(path)
      source.each_line do |l|
        if l.starts_with?('///') && !(m = %r!^///\s*<reference\s+path=(?:"([^"]+)"|'([^']+)')\s*/>\s*!.match(l)).nil?
          matched_path = m.captures.compact[0]
          abs_matched_path = File.expand_path(matched_path, File.dirname(path))
          unless visited_paths.include? abs_matched_path
            block.call abs_matched_path
            get_all_reference_paths(abs_matched_path, nil, visited_paths, &block)
          end
        end
      end
    end

    # Compile source
    #
    # @param [String] ts_path
    # @param [String] source TypeScript source code
    # @param [Sprockets::Context] sprockets context object
    # @return [String] compiled JavaScript source code
    #
    def compile(ts_path, source, context=nil, *options)
      if context
        get_all_reference_paths(File.expand_path(ts_path), source) do |abs_path|
          context.depend_on abs_path
        end
      end
      begin
        command_path = npm_tsc_path()
        if command_path.empty?
          raise RuntimeError, "Failed to find typescript compiler in local or global node environment."
        end

        log("#{module_name} processing: #{ts_path}")

        # compile file
        s = replace_relative_references(ts_path, source)
        source_file = Tempfile.new(["typescript-rails", ".ts"])
        source_file.write(s)
        source_file.close
        args = self.default_options.map(&:dup)
        # _args = [ "--out /dev/stdout", "--noResolve" ]
        # if self.tsconfig && File.exist?(self.tsconfig)
        #   _args.push("--project #{self.tsconfig}")
        # end
        args.push(source_file.path)
        compiled_source, _, status = run_command(command_path, args)

        filtered_output = nil

        # Parse errors from output: there is no way (currently) to suppress the
        # errors emitted when passing --noResolve argument to tsc.
        #
        # Status values:
        #   Success = 0
        #   DiagnosticsPresent_OutputsSkipped = 1
        #   DiagnosticsPresent_OutputsGenerated = 2
        #
        # See: https://github.com/Microsoft/TypeScript/blob/master/src/compiler/types.ts
        #
        # Ignore the following error codes:
        #   TS2304: Cannot find name ...
        #   TS2307: Cannot find module ...
        #   TS2318: Cannot find global type ...
        #   TS2339: Property ... does not exist on type ... **
        #   TS2468: Cannot find global value ...
        #   TS2503: Cannot find namespace ...
        #   TS2662: Cannot find name ...  Did you mean the static member ...
        #   TS2663: Cannot find name ... Did you mean the instance member ...
        #   TS2688: Cannot find type definition file for ...
        #   TS2694: Namespace ... has no exported member ... **
        #
        # See: https://github.com/Microsoft/TypeScript/blob/master/src/compiler/diagnosticMessages.json
        #
        unless status.success?
          filtered_output = ""
          ignore_errors = [
            "TS2304",
            "TS2307",
            "TS2318",
            "TS2339",
            "TS2468",
            "TS2503",
            "TS2662",
            "TS2663",
            "TS2688",
            "TS2694"
          ]
          regex = /#{Regexp.escape(File.basename(source_file))}\(([\d]+,[\d]+)\):[\s]+error[\s]+(TS[\d]+):[\s]+(.*)$/
          errors = []
          compiled_source.split("\n").each do |line|
            if (matches = line.match(regex))
              errors << {
                code: matches[2],
                message: matches[3],
                line: line,
                line_position: matches[1]
              }
              next
            end
            filtered_output << line << "\n"
          end
          # iterate over errors and log ignored, raise exception for all others
          errors.each do |error|
            log("#{module_name} parsing error for file: #{ts_path}, #{error[:code]}@(#{error[:line_position]}): #{error[:message]}")
            unless ignore_errors.include?(error[:code])
              raise TypescriptCompileError, "#{error[:code]}@(#{error[:line_position]}): #{error[:message]}"
            end
          end
        end
        filtered_output ||= compiled_source
      rescue Exception => e
        raise "Typescript error in file '#{ts_path}':\n#{e.message}"
      ensure
        source_file.unlink
      end
    end

    private
      # Returns closest path for npm bin directory
      #
      # The resolution process favors a local node_modules directory over a
      # global installation.
      #
      # @return [String] path to directory on success, otherwise empty string
      #
      def npm_bin_path
        npm_bin_path, stderr, status = run_command("npm", ["bin"])
        unless status.success? && File.directory?(npm_bin_path.chomp!)
          # try again with global resolution
          npm_bin_path, stderr, status = run_command("npm", ["--global", "bin"])
          unless status.success? && File.directory?(npm_bin_path.chomp!)
            npm_bin_path = ""
          end
        end
        npm_bin_path
      end

      # Returns path to typescript compiler (tsc)
      #
      # The resolution process examines local and global installation paths.
      #
      # @return [String] path to tsc on success, otherwise empty string
      # @see npm_bin_path
      #
      def npm_tsc_path
        npm_tsc_path = ""
        npm_bin_path = npm_bin_path()
        unless npm_bin_path.empty?
          npm_tsc_path = [npm_bin_path, "tsc"].join('/')
          unless File.executable?(npm_tsc_path)
            npm_tsc_path = ""
          end
        end
        npm_tsc_path
      end

      # Run a command with arguments
      #
      # @return [String, String, Process::Status] stdout, stderr, and the status
      #   of the command results.
      # @see Process::Status
      #
      def run_command(command, args=[])
        args_string = args.join(" ")
        _stdout, _stderr, _status = Open3.capture3("\"#{command}\" #{args_string}")
      end

      # Log a message
      #
      # Checks if a logger has been configured before attempting to log.
      #
      # @param [String] message to be logged
      #
      def log(message)
        if self.logger
          self.logger.debug(message)
        end
      end

      # Returns module name
      #
      # @return [String] module name
      #
      def module_name
        Module.nesting.last
      end
  end

  # @TODO: we should honor the tsconfig.json file if it exists!
  # @NOTE: we need to specify --removeComments to pass some parsing in tests. (should be an option)
  # self.default_options = ["--target es5", "--outFile /dev/stdout", "--noResolve", "--removeComments"]
end
