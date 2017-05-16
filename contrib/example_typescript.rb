#
# initializers/typescript.rb
#
# Configure typescript-monkey gem, notably which typescript path to use.
# See: https://github.com/markeissler/typescript-monkey
#

Typescript::Monkey.configure do |config|
  # Configure Typescript::Monkey concatenated compilation
  # config.compile = false

  # Configure Typescript::Monkey logging (for debugging your app build)
  # config.logger = Rails.logger
end
