require File.join(File.dirname(__FILE__), 'test_helper.rb')
require 'typescript-rails'

require 'action_controller/railtie'
require 'sprockets/railtie'

class AssetsTest < ActiveSupport::TestCase
  include Minitest::PowerAssert::Assertions

  @@app_setup = false
  @@app = nil

  def setup
    unless @@app_setup == true
      @@app_setup = true
      FileUtils.mkdir_p tmp_path

      @@app = Class.new(Rails::Application)

      @@app.config.eager_load = false
      @@app.config.active_support.deprecation = :stderr
      @@app.config.assets.configure do |env|
        env.cache = ActiveSupport::Cache.lookup_store(:memory_store)
      end
      @@app.config.assets.paths << "#{File.dirname(__FILE__)}/fixtures/assets"
      @@app.paths['log'] = "#{tmp_path}/log/test.log"

      @@app.initialize!
    end
  end

  def teardown
    FileUtils.rm_rf tmp_path
  end

  def tmp_path
    "#{File.dirname(__FILE__)}/tmp"
  end

  #
  # These tests require sprockets processing with --noResolve turned off which
  # results in reference resolution and concatenated files.
  #
  # Typescript::Rails::Compiler.compile = false
  #

  test 'assets .js.ts is compiled from TypeScript to JavaScript' do
    byebug
    assert { @@app.assets['javascripts/hello.js'].present? }
    assert { @@app.assets['javascripts/hello.js'].source.include?('var log_to_console = function (x) {') }
    assert { @@app.assets['javascripts/hello.js'].source.include?('var s = "Hello, world!";') }
  end
end
