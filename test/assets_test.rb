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
      # reconfigure compiler to resolve references and concatenate files
      Typescript::Rails.configure do |config|
        config.compile = true
      end

      @@app = RailsApp.instance.app()
      RailsApp.instance.asset_paths_append("#{File.dirname(__FILE__)}/fixtures/assets")
    end
  end

  def teardown
  end

  #
  # These tests require sprockets processing with --noResolve turned off which
  # results in reference resolution and concatenated files.
  #
  # Typescript::Rails::Compiler.compile = true
  #

  test 'assets .js.ts is compiled from TypeScript to JavaScript' do
    assert { @@app.assets['javascripts/hello.js'].present? }
    assert { @@app.assets['javascripts/hello.js'].source.include?('var log_to_console = function (x) {') }
    assert { @@app.assets['javascripts/hello.js'].source.include?('var s = "Hello, world!";') }
  end
end
