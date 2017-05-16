require 'typescript/monkey/package'

module Typescript::Monkey
  class << self
    attr_accessor :configuration
  end

  def self.configure(&block)
    self.configuration ||= Configuration.new
    block.call(configuration) if block_given?
  end

  class Configuration

    attr_accessor :options
    attr_accessor :logger

    def initialize
      @_default_options = [
        "--target es5",
        "--outFile /dev/stdout",
        "--noResolve",
        "--removeComments",
        "--typeRoots ['#{File.expand_path("../lib", Typescript::Monkey::Package.metadata_path())}']"
      ]
      @options = @_default_options.to_set
      @compile = false;
      @logger = nil;
    end

    def default_options
      @_default_options.to_enum
    end

    def compile=(value)
      unless (!!value == value)
        raise TypeError, "#{method(__method__).owner}.#{__method__}: value parameter must be type Bool"
      end

      if value == true
        @options.delete("--noResolve")
        @compile = true
      else
        @options.add("--noResolve")
        @compile = false
      end
    end
  end
end
