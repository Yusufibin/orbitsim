require 'spec_helper'

if defined?(OrbitSim::Renderer::Graphic)
  RSpec.describe OrbitSim::Renderer::Graphic do
  let(:bodies) do
    [
      OrbitSim::Body.new(
        mass: 1.989e30,
        position: Vector[0, 0, 0],
        velocity: Vector[0, 0, 0],
        name: 'Sun',
        color: 'yellow',
        radius: 6.96e8
      ),
      OrbitSim::Body.new(
        mass: 5.972e24,
        position: Vector[1.496e11, 0, 0],
        velocity: Vector[0, 2.978e4, 0],
        name: 'Earth',
        color: 'blue',
        radius: 6.371e6
      )
    ]
  end

  let(:simulation) { OrbitSim::Simulation.new(bodies) }

  # Mock Ruby2D classes
  let(:mock_window) { double('Ruby2D::Window') }
  let(:mock_circle) { double('Ruby2D::Circle') }
  let(:mock_line) { double('Ruby2D::Line') }
  let(:mock_rectangle) { double('Ruby2D::Rectangle') }
  let(:mock_text) { double('Ruby2D::Text') }

  before do
    # Stub Ruby2D classes
    stub_const('Ruby2D::Window', double(new: mock_window))
    stub_const('Ruby2D::Circle', double(new: mock_circle))
    stub_const('Ruby2D::Line', double(new: mock_line))
    stub_const('Ruby2D::Rectangle', double(new: mock_rectangle))
    stub_const('Ruby2D::Text', double(new: mock_text))

    allow(mock_window).to receive(:width).and_return(800)
    allow(mock_window).to receive(:height).and_return(600)
    allow(mock_window).to receive(:show)
    allow(mock_window).to receive(:update)
    allow(mock_window).to receive(:clear)
  end

  let(:renderer) { described_class.new(simulation) }

  describe '#initialize' do
    it 'sets simulation and initializes state' do
      expect(renderer.instance_variable_get(:@simulation)).to eq(simulation)
      expect(renderer.zoom).to eq(1e-9)
      expect(renderer.offset_x).to eq(400)
      expect(renderer.offset_y).to eq(300)
      expect(renderer.speed).to eq(1.0)
      expect(renderer.paused).to be false
    end

    it 'initializes trajectories' do
      trajectories = renderer.instance_variable_get(:@trajectories)
      expect(trajectories.keys.size).to eq(2)
      trajectories.each_value do |pos_list|
        expect(pos_list.size).to eq(1)
        expect(pos_list.first).to eq([0, 0])
      end
    end
  end

  describe '#speed=' do
    it 'sets speed and updates simulation dt' do
      renderer.speed = 2.0
      expect(renderer.speed).to eq(2.0)
      expect(simulation.dt).to eq(0.01 / 2.0)
    end
  end

  describe '#world_to_screen' do
    it 'converts world coordinates to screen coordinates' do
      world_x, world_y = 1e9, 2e9
      screen_x, screen_y = renderer.send(:world_to_screen, world_x, world_y)
      expected_x = world_x * renderer.zoom + renderer.offset_x
      expected_y = world_y * renderer.zoom + renderer.offset_y
      expect(screen_x).to eq(expected_x)
      expect(screen_y).to eq(expected_y)
    end
  end

  describe '#screen_to_world' do
    it 'converts screen coordinates to world coordinates' do
      screen_x, screen_y = 500, 400
      world_x, world_y = renderer.send(:screen_to_world, screen_x, screen_y)
      expected_x = (screen_x - renderer.offset_x) / renderer.zoom
      expected_y = (screen_y - renderer.offset_y) / renderer.zoom
      expect(world_x).to eq(expected_x)
      expect(world_y).to eq(expected_y)
    end
  end

  describe '#find_body_at' do
    it 'finds body at screen coordinates' do
      # Place screen coords at Earth's position
      earth_screen_x, earth_screen_y = renderer.send(:world_to_screen, 1.496e11, 0)
      body = renderer.send(:find_body_at, earth_screen_x, earth_screen_y)
      expect(body).to eq(bodies.last) # Earth
    end

    it 'returns nil when no body is found' do
      body = renderer.send(:find_body_at, 100, 100)
      expect(body).to be_nil
    end
  end

  describe '#update_trajectories' do
    it 'updates trajectory positions' do
      initial_trajectories = renderer.instance_variable_get(:@trajectories).dup
      simulation.step
      renderer.send(:update_trajectories)
      trajectories = renderer.instance_variable_get(:@trajectories)
      trajectories.each do |body, positions|
        expect(positions.size).to eq(2) # Initial + new position
        expect(positions.last).not_to eq(positions.first)
      end
    end

    it 'limits trajectory length' do
      # Add many positions
      1001.times do
        simulation.step
        renderer.send(:update_trajectories)
      end
      trajectories = renderer.instance_variable_get(:@trajectories)
      trajectories.each_value do |positions|
        expect(positions.size).to eq(1000) # Should be limited to 1000
      end
    end
  end

  describe '#generate_starfield' do
    it 'generates specified number of stars' do
      stars = renderer.send(:generate_starfield, 50)
      expect(stars.size).to eq(50)
      stars.each do |star|
        expect(star).to have_key(:x)
        expect(star).to have_key(:y)
        expect(star).to have_key(:size)
        expect(star).to have_key(:color)
        expect(star[:x]).to be_between(0, 799)
        expect(star[:y]).to be_between(0, 599)
      end
    end
  end

  describe '#parse_color' do
    it 'parses color names to ChunkyPNG colors' do
      color = renderer.send(:parse_color, 'red')
      expect(color).to eq(ChunkyPNG::Color::RED)
    end

    it 'defaults to white for unknown colors' do
      color = renderer.send(:parse_color, 'unknown')
      expect(color).to eq(ChunkyPNG::Color::WHITE)
    end
  end

  # Note: render method is hard to test without full Ruby2D setup
  # Focus on data handling aspects that are testable
  end
end