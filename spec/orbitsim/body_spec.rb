require 'spec_helper'

RSpec.describe OrbitSim::Body do
  let(:mass) { 1.989e30 } # Sun-like mass
  let(:position) { Vector[1.496e11, 0, 0] } # 1 AU in x direction
  let(:velocity) { Vector[0, 2.978e4, 0] } # Earth-like velocity in y direction
  let(:color) { 'yellow' }
  let(:radius) { 6.96e8 }
  let(:name) { 'Sun' }

  let(:body) do
    described_class.new(
      mass: mass,
      position: position,
      velocity: velocity,
      color: color,
      radius: radius,
      name: name
    )
  end

  describe '#initialize' do
    it 'sets all attributes correctly' do
      expect(body.mass).to eq(mass)
      expect(body.position).to eq(position)
      expect(body.velocity).to eq(velocity)
      expect(body.color).to eq(color)
      expect(body.radius).to eq(radius)
      expect(body.name).to eq(name)
    end

    it 'uses default values for optional attributes' do
      body = described_class.new(mass: mass, position: position, velocity: velocity)
      expect(body.color).to eq('white')
      expect(body.radius).to eq(1.0)
      expect(body.name).to eq('')
    end
  end

  describe '#update_position' do
    it 'updates position based on velocity and time step' do
      dt = 60 # 1 minute
      initial_position = body.position.dup
      body.update_position(dt)
      expected_position = initial_position + velocity * dt
      expect(body.position).to eq(expected_position)
    end
  end

  describe '#gravitational_force' do
    let(:other_body) do
      described_class.new(
        mass: 5.972e24, # Earth mass
        position: Vector[0, 0, 0],
        velocity: Vector[0, 0, 0]
      )
    end

    it 'calculates gravitational force correctly' do
      force = body.gravitational_force(other_body)
      r_vector = other_body.position - body.position
      r = r_vector.magnitude
      expected_force_magnitude = described_class::G * body.mass * other_body.mass / (r ** 2)
      unit_vector = r_vector / r
      expected_force = expected_force_magnitude * unit_vector

      expect(force).to eq(expected_force)
    end

    it 'returns zero force when bodies are at the same position' do
      same_position_body = described_class.new(
        mass: 1e20,
        position: body.position,
        velocity: Vector[0, 0, 0]
      )
      force = body.gravitational_force(same_position_body)
      expect(force).to eq(Vector[0, 0, 0])
    end
  end

  describe '#to_s' do
    it 'returns a string representation of the body' do
      expected = "Body(name: Sun, mass: #{mass}, pos: #{position}, vel: #{velocity})"
      expect(body.to_s).to eq(expected)
    end
  end
end