require 'matrix'
require 'json'

module OrbitSim
  # Manages a collection of Body objects for N-body gravitational simulation.
  # Performs Euler integration to update positions and velocities over time steps.
  # Handles adding/removing bodies, stepping simulation, calculating total energy,
  # and providing data for rendering.
  class Simulation
    attr_reader :bodies, :dt

    # Initializes a new simulation with a collection of bodies and time step.
    #
    # @param bodies [Array<Body>] Initial collection of celestial bodies.
    # @param dt [Float] Time step for integration (default: 0.01).
    def initialize(bodies, dt: 0.01)
      @bodies = bodies
      @dt = dt
      @time = 0
    end

    def time
      @time
    end

    def kinetic_energy
      @bodies.sum { |body| 0.5 * body.mass * body.velocity.magnitude**2 }
    end

    def potential_energy
      potential = 0
      @bodies.combination(2).each do |body1, body2|
        r = (body1.position - body2.position).magnitude
        potential -= OrbitSim::Body::G * body1.mass * body2.mass / r if r > 0
      end
      potential
    end

    # Loads a simulation from a JSON file.
    #
    # @param file [String] Path to the JSON file.
    # @return [Simulation] The loaded simulation.
    def self.from_json(file)
      data = JSON.parse(File.read(file))
      bodies = data['bodies'].map do |body_data|
        Body.new(
          mass: body_data['mass'],
          position: Vector[*body_data['position']],
          velocity: Vector[*body_data['velocity']],
          color: body_data['color'],
          radius: body_data['radius'],
          name: body_data['name']
        )
      end
      new(bodies, dt: data['dt'])
    end

    # Saves the simulation to a JSON file.
    #
    # @param file [String] Path to the JSON file.
    def to_json(file)
      data = {
        dt: @dt,
        bodies: @bodies.map do |body|
          {
            mass: body.mass,
            position: body.position.to_a,
            velocity: body.velocity.to_a,
            color: body.color,
            radius: body.radius,
            name: body.name
          }
        end
      }
      File.write(file, JSON.pretty_generate(data))
    end

    # Adds a body to the simulation.
    #
    # @param body [Body] The body to add.
    def add_body(body)
      @bodies << body
    end

    # Removes a body from the simulation.
    #
    # @param body [Body] The body to remove.
    def remove_body(body)
      @bodies.delete(body)
    end

    # Advances the simulation by one time step using Euler integration.
    #
    # Calculates forces on all bodies, updates velocities and positions.
    def step
      forces = calculate_forces
      @bodies.each_with_index do |body, i|
        acceleration = forces[i] / body.mass
        body.velocity += acceleration * @dt
        body.position += body.velocity * @dt
      end
      @time += @dt
    end

    # Calculates the total energy of the system (kinetic + potential).
    #
    # @return [Float] The total energy.
    def total_energy
      kinetic = @bodies.sum { |body| 0.5 * body.mass * body.velocity.magnitude**2 }
      potential = 0
      @bodies.combination(2).each do |body1, body2|
        r = (body1.position - body2.position).magnitude
        potential -= OrbitSim::Body::G * body1.mass * body2.mass / r if r > 0
      end
      kinetic + potential
    end

    # Provides data for rendering the simulation.
    #
    # @return [Array<Hash>] Array of hashes with position, color, radius, and name for each body.
    def render_data
      @bodies.map { |body| { position: body.position, color: body.color, radius: body.radius, name: body.name } }
    end

    def run(renderer, steps: 1000, speed: 1)
      steps.times do
        step
        renderer.render
        sleep(@dt / speed) if speed > 0
      end
    end

    private

    def calculate_forces
      forces = Array.new(@bodies.size) { Vector[0, 0, 0] }
      @bodies.each_with_index do |body1, i|
        @bodies.each_with_index do |body2, j|
          next if i == j
          forces[i] += body1.gravitational_force(body2)
        end
      end
      forces
    end
  end
end