module Typescript::Monkey
  require 'open3'

  #
  # The CLI class.
  #
  # A class that implements a basic interface to command line programs.
  #
  class CLI
      # Run a command with arguments
      #
      # @return [String, String, Process::Status] stdout, stderr, and the status
      #   of the command results.
      #
      # @see Process::Status
      #
      def self.run_command(command, args=[])
        args_string = args.join(" ")
        _stdout, _stderr, _status = Open3.capture3("\"#{command}\" #{args_string}")
      end
  end
end
