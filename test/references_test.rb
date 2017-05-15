require File.join(File.dirname(__FILE__), 'test_helper.rb')
require 'typescript-monkey'

require 'action_controller/railtie'
require 'sprockets/railtie'

class ReferencesTest < ActiveSupport::TestCase
  include Minitest::PowerAssert::Assertions

  @@app_setup = false
  @@app = nil

  def setup
    unless @@app_setup == true
      @@app_setup = true
      # reconfigure compiler to resolve references and concatenate files
      Typescript::Monkey.configure do |config|
        config.compile = true
      end

      @@app = RailsApp.instance.app()
      RailsApp.instance.asset_paths_append("#{File.dirname(__FILE__)}/fixtures/references")
    end
  end

  def teardown
  end

  #
  # These tests require sprockets processing with --noResolve turned off which
  # results in reference resolution and concatenated files.
  #
  # Typescript::Monkey::Compiler.compile = true
  #

  test '<reference> to other .ts file works' do
    assert {@@app.assets['ref1_2.js'].source.match(/var f = function \(x, y\) \{\s*return x \+ y\;\s*\}\;\s*f\(1, 2\)\;\s*/) }
  end

  test '<reference> to other .d.ts file works' do
    assert {@@app.assets['ref2_2.js'].source.match(/f\(1, 2\)\;\s*/) }
  end

  test '<reference> to multiple .ts files works' do
    assert {@@app.assets['ref3_1.js'].source.match(/var f1 = function \(\) \{\s*\}\;\s*var f2 = function \(\) \{\s*\}\;\s*f1\(\)\;\s*f2\(\)\;/) }
  end

end
