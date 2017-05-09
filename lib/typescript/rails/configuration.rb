module Typescript::Rails
  class Configuration

    attr_reader   :default_options
    attr_accessor :options
    attr_accessor :tsconfig
    attr_accessor :logger

    def intialize
      @default_options = ["--target es5", "--outFile /dev/stdout", "--noResolve"];
      @options = nil;
      @tsconfig = nil;
      @logger = nil;
    end

  end
end
