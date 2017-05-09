# Configure coveralls environment

require 'coveralls'
require 'simplecov'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
])
SimpleCov.start do
  add_filter '.bundle/'
end

# Configure Rails environment
ENV['RAILS_ENV'] = 'test'

require 'rails'
require 'rails/test_help'
require 'minitest-power_assert'
require 'byebug'

# For generators
require 'rails/generators/test_case'

# Set ActiveSupport test order (:random, :sorted, :parallel)
ActiveSupport::TestCase.test_order = :random

# Default Typescript::Rails compiler configuration
require 'typescript/rails/configuration'
Typescript::Rails.configure do |config|
  # option config
  config.compile = false
  # setup logging for debugging
  debug_log_path = Pathname.new("#{File.dirname(__FILE__)}/tmp/log")
  FileUtils.mkdir_p(debug_log_path)
  config.logger = Logger.new(debug_log_path.join("typescript-rails.log").to_s)
end

def copy_routes
  routes = File.expand_path('../support/routes.rb', __FILE__)
  destination = File.join(destination_root, 'config')

  FileUtils.mkdir_p(destination)
  FileUtils.cp routes, destination
end

def strip_comments(source)
  source.gsub(%r{^//[^\n]*}m, '')
end

require 'rails'

class RailsApp
  attr_accessor :app

  def initialize(tmp_path, log_path)
    FileUtils.mkdir_p(tmp_path)

    @app = Class.new(Rails::Application)
    @app.config.eager_load = false
    @app.config.active_support.deprecation = :stderr
    @app.config.assets.configure do |env|
      env.cache = ActiveSupport::Cache.lookup_store(:memory_store)
    end
    # note: you could configure all asset paths here at once but that prevents
    # isolation for each test:
    #
    # @app.config.assets.paths << "#{File.dirname(__FILE__)}/fixtures/references"
    #
    @app.paths['log'] = log_path.to_s
    @app.paths['tmp'] = tmp_path.to_s
    @app.config.secret_key_base = "abcd1234"
    @app.initialize!

    ObjectSpace.define_finalizer(self, self.class.method(:finalize))
  end

  private_class_method :new

  def asset_paths_append(*paths)
    updated_paths = @app.config.assets.paths.to_set
    paths.each { |path| updated_paths.add(path) }
    @app.config.assets.paths = updated_paths.to_a
    # rebuild assets -- this will slow things down!
    @app.assets = Sprockets::Railtie.build_environment(@app)
  end

  def asset_paths_delete(*paths)
    updated_paths = @app.config.assets.paths.to_set
    paths.each { |path| updated_paths.delete(path) }
    @app.config.assets.paths = updated_paths.to_a
    # rebuild assets -- this will slow things down!
    @app.assets = Sprockets::Railtie.build_environment(@app)
  end

  def self.instance
    @__instance__ ||= begin
      @__tmp_path__ ||= Pathname.new("#{File.dirname(__FILE__)}/tmp")
      @__log_path__ ||= @__tmp_path__.join("log/test.log")
      @__instance__ ||= new(@__tmp_path__, @__log_path__)
    end
  end

  def self.finalize(object_id)
    # if logging has been configured, assume we want to keep the logs!
    unless Typescript::Rails.configuration.logger
      FileUtils.rm_rf(@__tmp_path__)
    end
  end

end
