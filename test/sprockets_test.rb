require File.join(File.dirname(__FILE__), 'test_helper.rb')
require 'typescript-rails'

require 'action_controller/railtie'
require 'sprockets/railtie'

class SprocketsTest < ActiveSupport::TestCase
  include Minitest::PowerAssert::Assertions

  @@app_setup = false
  @@app = nil

  def setup
    unless @@app_setup == true
      @@app_setup = true
      @@app = RailsApp.instance.app()
      RailsApp.instance.asset_paths_append("#{File.dirname(__FILE__)}/fixtures/sprockets")
    end
  end

  def teardown
  end

  #
  # These tests require sprockets processing with --noResolve turned on which
  # results in no reference resolution. Separate files will be output.
  #
  #
  # Typescript::Rails::Compiler.compile = false (default setting)
  #

  test '//= require directives work' do
    assert { @@app.assets['ref1_manifest.js'].source.match(/var f = function \(x, y\) \{\s*return x \+ y\;\s*\}\;\s*f\(1, 2\)\;\s*/) }
  end

end
