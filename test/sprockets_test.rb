require File.join(File.dirname(__FILE__), 'test_helper.rb')
require 'typescript-rails'

require 'action_controller/railtie'
require 'sprockets/railtie'

class SiteController < ActionController::Base
  self.view_paths = File.expand_path('../fixtures', __FILE__)
end

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
      @@app.config.assets.paths << "#{File.dirname(__FILE__)}/fixtures/sprockets"
      @@app.paths['log'] = "#{tmp_path}/log/test.log"
      @@app.config.secret_key_base = "abcd1234"

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
  # These tests require sprockets processing with --noResolve turned on which
  # results in no reference resolution. Separate files will be output.
  #
  #
  # Typescript::Rails::Compiler.compile = true (default setting)
  #

  test '//= require directives work' do
    assert { @@app.assets['ref1_manifest.js'].source.match(/var f = function \(x, y\) \{\s*return x \+ y\;\s*\}\;\s*f\(1, 2\)\;\s*/) }
  end

end
