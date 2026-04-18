require_relative "orbitsim/version"
require_relative "orbitsim/body"
require_relative "orbitsim/simulation"
require_relative "orbitsim/renderer/terminal"
begin
  require 'ruby2d'
  require_relative "orbitsim/renderer/graphic"
rescue LoadError
  # Graphic renderer not available
end
require_relative "orbitsim/presets"

module OrbitSim
  # Your code goes here...
end