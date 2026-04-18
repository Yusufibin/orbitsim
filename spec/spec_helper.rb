require 'simplecov'
SimpleCov.start

require 'rspec'
require 'matrix'

# Load the library
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

# Conditionally require optional dependencies
begin
  require 'rmagick'
rescue LoadError
  # RMagick not available
end

begin
  require 'chunky_png'
rescue LoadError
  # ChunkyPNG not available
end

begin
  require 'ruby2d'
rescue LoadError
  # Ruby2D not available
end

require 'orbitsim'

# Configure RSpec
RSpec.configure do |config|
  config.order = :random
  config.color = true
  config.formatter = :documentation

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end