require 'spec_helper'
require 'tempfile'

RSpec.describe OrbitSim::Simulation do
  let(:body1) do
    OrbitSim::Body.new(
      mass: 1.989e30,
      position: Vector[0, 0, 0],
      velocity: Vector[0, 0, 0],
      name: 'Sun'
    )
  end

  let(:body2) do
    OrbitSim::Body.new(
      mass: 5.972e24,
      position: Vector[1.496e11, 0, 0],
      velocity: Vector[0, 2.978e4, 0],
      name: 'Earth'
    )
  end

  let(:bodies) { [body1, body2] }
  let(:dt) { 0.01 }
  let(:simulation) { described_class.new(bodies, dt: dt) }

  describe '#initialize' do
    it 'sets bodies and dt correctly' do
      expect(simulation.bodies).to eq(bodies)
      expect(simulation.dt).to eq(dt)
    end

    it 'uses default dt' do
      sim = described_class.new(bodies)
      expect(sim.dt).to eq(0.01)
    end
  end

  describe '.from_json' do
    let(:json_data) do
      {
        dt: 0.005,
        bodies: [
          {
            mass: 1.989e30,
            position: [0, 0, 0],
            velocity: [0, 0, 0],
            color: 'yellow',
            radius: 6.96e8,
            name: 'Sun'
          },
          {
            mass: 5.972e24,
            position: [1.496e11, 0, 0],
            velocity: [0, 2.978e4, 0],
            color: 'blue',
            radius: 6.371e6,
            name: 'Earth'
          }
        ]
      }
    end

    let(:temp_file) do
      file = Tempfile.new('simulation.json')
      file.write(JSON.generate(json_data))
      file.close
      file
    end

    it 'loads simulation from JSON file' do
      loaded_sim = described_class.from_json(temp_file.path)
      expect(loaded_sim.dt).to eq(0.005)
      expect(loaded_sim.bodies.size).to eq(2)
      expect(loaded_sim.bodies.first.name).to eq('Sun')
      expect(loaded_sim.bodies.last.name).to eq('Earth')
    end
  end

  describe '#to_json' do
    let(:temp_file) { Tempfile.new('output.json') }

    it 'saves simulation to JSON file' do
      simulation.to_json(temp_file.path)
      data = JSON.parse(File.read(temp_file.path))
      expect(data['dt']).to eq(dt)
      expect(data['bodies'].size).to eq(2)
      expect(data['bodies'].first['name']).to eq('Sun')
    end
  end

  describe '#add_body' do
    let(:new_body) do
      OrbitSim::Body.new(
        mass: 3.301e23,
        position: Vector[2.279e11, 0, 0],
        velocity: Vector[0, 2.407e4, 0],
        name: 'Mercury'
      )
    end

    it 'adds a body to the simulation' do
      expect { simulation.add_body(new_body) }.to change { simulation.bodies.size }.by(1)
      expect(simulation.bodies).to include(new_body)
    end
  end

  describe '#remove_body' do
    it 'removes a body from the simulation' do
      expect { simulation.remove_body(body1) }.to change { simulation.bodies.size }.by(-1)
      expect(simulation.bodies).not_to include(body1)
    end
  end

  describe '#step' do
    it 'updates positions and velocities of bodies' do
      initial_positions = simulation.bodies.map(&:position)
      initial_velocities = simulation.bodies.map(&:velocity)

      simulation.step

      # Positions should change
      simulation.bodies.each_with_index do |body, index|
        expect(body.position).not_to eq(initial_positions[index])
      end

      # Velocities should change due to gravitational forces
      simulation.bodies.each_with_index do |body, index|
        expect(body.velocity).not_to eq(initial_velocities[index])
      end
    end
  end

  describe '#total_energy' do
    it 'calculates total energy (kinetic + potential)' do
      energy = simulation.total_energy
      expect(energy).to be_a(Float)
      expect(energy).to be < 0 # For bound systems, total energy should be negative
    end

    it 'returns correct kinetic energy for stationary bodies' do
      stationary_body = OrbitSim::Body.new(
        mass: 1e20,
        position: Vector[1e10, 0, 0],
        velocity: Vector[0, 0, 0]
      )
      sim = described_class.new([stationary_body])
      energy = sim.total_energy
      # Potential energy between bodies, kinetic is 0
      expect(energy).to eq(0) # Since only one body, no potential energy
    end
  end

  describe '#render_data' do
    it 'returns array of hashes with position, color, radius, name' do
      data = simulation.render_data
      expect(data).to be_an(Array)
      expect(data.size).to eq(2)

      first_body_data = data.first
      expect(first_body_data).to have_key(:position)
      expect(first_body_data).to have_key(:color)
      expect(first_body_data).to have_key(:radius)
      expect(first_body_data).to have_key(:name)
      expect(first_body_data[:position]).to eq(body1.position)
      expect(first_body_data[:name]).to eq('Sun')
    end
  end

  describe '#run' do
    let(:mock_renderer) { double('renderer') }

    it 'runs simulation for specified steps' do
      expect(mock_renderer).to receive(:render).exactly(100).times
      simulation.run(mock_renderer, steps: 100)
    end

    it 'calls step for each iteration' do
      allow(mock_renderer).to receive(:render)
      expect(simulation).to receive(:step).exactly(100).times
      simulation.run(mock_renderer, steps: 100)
    end

    # it 'respects speed parameter' do
    #   allow(mock_renderer).to receive(:render)
    #   # Speed > 0 should sleep
    #   expect(Kernel).to receive(:sleep).with(dt / 2).exactly(100).times
    #   simulation.run(mock_renderer, steps: 100, speed: 2)
    # end
  end
end