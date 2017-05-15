# require File.join(File.dirname(__FILE__), 'test_helper.rb')
require 'test_helper'
require 'action_controller'
require 'typescript-monkey'
require 'sprockets/railtie'

class SiteController < ActionController::Base
  self.view_paths = File.expand_path('../fixtures', __FILE__)
end

DummyApp = ActionDispatch::Routing::RouteSet.new
DummyApp.draw do
  get 'site/index'
  get 'site/es5'
end

class TemplateHandlerTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    @app ||= DummyApp
  end

  test 'typescript views are served as javascript' do
    get '/site/index.js'
    assert_match(/var x = 5;\s*/, strip_comments(last_response.body))
  end

  test 'ES5 features' do
    get '/site/es5.js'
    assert_equal(200, last_response.status)
  end

  # @TODO: need a test for <script type="text/typescript"></script>
end
