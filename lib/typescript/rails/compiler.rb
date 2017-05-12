require 'typescript/rails'
require 'typescript/rails/package'

module Typescript::Rails::Compiler
  class TypescriptCompileError < RuntimeError; end

  class << self
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
        command_path = Typescript::Rails::Package.compiler_bin()
        if command_path.nil?
          raise RuntimeError, "Failed to find typescript compiler in local or global node environment."
        end

        log("#{module_name} processing: #{ts_path}")

        # compile file
        s = replace_relative_references(ts_path, source)
        source_file = Tempfile.new(["typescript-rails", ".ts"])
        source_file.write(s)
        source_file.close
        args = Typescript::Rails.configuration.options.map(&:dup)
        # _args = [ "--out /dev/stdout", "--noResolve" ]
        # if self.tsconfig && File.exist?(self.tsconfig)
        #   _args.push("--project #{self.tsconfig}")
        # end
        args.push(source_file.path)
        compiled_source, _, status = Typescript::Rails::CLI.run_command(command_path, args)

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

      # Log a message
      #
      # Checks if a logger has been configured before attempting to log.
      #
      # @param [String] message to be logged
      #
      def log(message)
        if Typescript::Rails.configuration.logger
          Typescript::Rails.configuration.logger.debug(message)
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

end
