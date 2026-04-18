require 'spec_helper'
require 'stringio'

RSpec.describe OrbitSim::Renderer::Terminal do
  let(:bodies) do
    [
      OrbitSim::Body.new(
        mass: 1.989e30,
        position: Vector[0, 0, 0],
        velocity: Vector[0, 0, 0],
        name: 'Sun',
        radius: 6.96e8
      ),
      OrbitSim::Body.new(
        mass: 5.972e24,
        position: Vector[1.496e11, 0, 0],
        velocity: Vector[0, 2.978e4, 0],
        name: 'Earth',
        radius: 6.371e6
      )
    ]
  end

  let(:simulation) { OrbitSim::Simulation.new(bodies) }
  let(:renderer) { described_class.new(simulation) }

  describe '#initialize' do
    it 'sets simulation and initializes state' do
      expect(renderer.instance_variable_get(:@simulation)).to eq(simulation)
      expect(renderer.instance_variable_get(:@paused)).to be false
      expect(renderer.instance_variable_get(:@speed)).to eq(1)
      expect(renderer.instance_variable_get(:@zoom)).to eq(1.0)
      expect(renderer.instance_variable_get(:@show_trails)).to be true
    end
  end

  describe '#render_simulation_view' do
    it 'generates an ASCII representation of the simulation' do
      view = renderer.send(:render_simulation_view)
      expect(view).to be_a(String)
      expect(view.lines.size).to be > 5
    end

    it 'places bodies on the grid' do
      view = renderer.send(:render_simulation_view)
      expect(view).to include('☀')
      expect(view).to include('●')
    end
  end

  describe '#render_info_panel' do
    it 'generates an info panel with body information' do
      panel = renderer.send(:render_info_panel)
      expect(panel).to be_a(String)
      expect(panel).to include('HELIOSIM')
      expect(panel).to include('Sun')
      expect(panel).to include('Earth')
    end

    it 'includes energy calculations' do
      panel = renderer.send(:render_info_panel)
      expect(panel).to include('Energy:')
      expect(panel).to include('Kinetic')
      expect(panel).to include('Potential')
    end
  end

  describe '#render' do
    let(:output) { StringIO.new }

    before do
      allow(STDOUT).to receive(:puts).and_return(nil)
      allow(STDOUT).to receive(:print).and_return(nil)
    end

    it 'renders to string when capture is true' do
      result = renderer.send(:render, true)
      expect(result).to be_a(String)
      expect(result).to include('Sun')
    end

it 'prints to stdout when capture is false' do
      renderer.send(:render, false)
    end
  end

  describe '#handle_input' do
    before do
      allow(IO).to receive(:console).and_return(double('console'))
      allow(IO.console).to receive(:read_nonblock).and_return(nil)
    end

    it 'handles pause input' do
      allow(IO.console).to receive(:read_nonblock).and_return(' ')
      renderer.send(:handle_input)
      expect(renderer.instance_variable_get(:@paused)).to be true
    end

    it 'handles speed changes' do
      allow(IO.console).to receive(:read_nonblock).and_return('2')
      renderer.send(:handle_input)
      expect(renderer.instance_variable_get(:@speed)).to eq(10)
    end

    it 'handles zoom changes' do
      initial_zoom = renderer.instance_variable_get(:@zoom)
      allow(IO.console).to receive(:read_nonblock).and_return('+')
      renderer.send(:handle_input)
      expect(renderer.instance_variable_get(:@zoom)).to be > initial_zoom
    end

    it 'handles trails toggle' do
      allow(IO.console).to receive(:read_nonblock).and_return('t')
      renderer.send(:handle_input)
      expect(renderer.instance_variable_get(:@show_trails)).to be false
    end

    it 'handles quit' do
      allow(IO.console).to receive(:read_nonblock).and_return('q')
      renderer.send(:handle_input)
      expect(renderer.instance_variable_get(:@running)).to be false
    end
  end

  describe '#update_trails' do
    it 'stores position history for each body' do
      renderer.send(:update_trails)
      expect(renderer.instance_variable_get(:@trails)).to be_a(Hash)
      expect(renderer.instance_variable_get(:@trails).keys.size).to eq(2)
    end
  end
end
