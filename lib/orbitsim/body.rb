require 'matrix'

module OrbitSim
  # Represents a celestial body in the orbital simulation.
  # Handles position updates and gravitational interactions.
  class Body
    # Gravitational constant (m^3 kg^-1 s^-2)
    G = 6.67430e-11

    attr_accessor :mass, :position, :velocity, :color, :radius, :name

    # Initializes a new celestial body.
    #
    # @param mass [Float] The mass of the body in kilograms.
    # @param position [Vector] The initial position vector (3D).
    # @param velocity [Vector] The initial velocity vector (3D).
    # @param color [String] The color for visualization (default: "white").
    # @param radius [Float] The radius for visualization (default: 1.0).
    # @param name [String] The name of the body (default: "").
    def initialize(mass:, position:, velocity:, color: "white", radius: 1.0, name: "")
      @mass = mass
      @position = position
      @velocity = velocity
      @color = color
      @radius = radius
      @name = name
    end

    # Updates the position of the body based on its velocity and time step.
    #
    # @param dt [Float] The time step in seconds.
    def update_position(dt)
      @position += @velocity * dt
    end

    # Calculates the gravitational force exerted on this body by another body.
    #
    # @param other [Body] The other celestial body.
    # @return [Vector] The force vector acting on this body due to the other body.
    def gravitational_force(other)
      r_vector = other.position - @position
      r = r_vector.magnitude

      return Vector[0, 0, 0] if r.zero?

      force_magnitude = G * @mass * other.mass / (r ** 2)
      unit_vector = r_vector / r
      force_magnitude * unit_vector
    end

    # Returns a string representation of the body.
    #
    # @return [String] String representation including name, mass, position, and velocity.
    def to_s
      "Body(name: #{name}, mass: #{mass}, pos: #{position}, vel: #{velocity})"
    end
  end
end