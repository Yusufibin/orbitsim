require 'spec_helper'
require 'thor'

# Simplified CLI class for testing
class OrbitSimCLI < Thor
  desc "simulate [PRESET]", "Run orbital simulation with given preset or loaded file"
  option :mode, type: :string, default: "terminal", enum: %w[terminal graphic]
  option :speed, type: :numeric, default: 1
  option :export, type: :string, enum: %w[png gif]
  option :frames, type: :numeric, default: 100
  option :save, type: :string
  option :load, type: :string
  def simulate(preset = nil)
    if options[:load]
      simulation = OrbitSim::Simulation.from_json(options[:load])
    elsif preset
      preset_data = OrbitSim::Presets.load(preset)
      simulation = OrbitSim::Simulation.new(preset_data)
    else
      raise "Either PRESET or --load must be provided"
    end
    renderer = case options[:mode]
                when "terminal"
                  OrbitSim::Renderer::Terminal.new(simulation)
                when "graphic"
                  OrbitSim::Renderer::Graphic.new(simulation)
                end
    if options[:export] == "png" && options[:mode] == "graphic"
      10.times { simulation.step }
      renderer.render
      renderer.export_png("#{preset || 'simulation'}.png")
    elsif options[:export] == "gif" && options[:mode] == "graphic"
      options[:frames].times do
        simulation.step
        renderer.render
        renderer.collect_frame
      end
      renderer.export_gif("#{preset || 'simulation'}.gif")
    elsif options[:mode] == "terminal"
      renderer.run
    elsif options[:mode] == "graphic"
      renderer.speed = options[:speed]
      renderer.run
    else
      simulation.run(renderer, speed: options[:speed])
    end
    if options[:save]
      simulation.to_json(options[:save])
    end
  end

  desc "list", "List available presets"
  def list
    puts OrbitSim::Presets.list.join("\n")
  end

  desc "version", "Show version"
  def version
    puts OrbitSim::VERSION
  end
end

RSpec.describe OrbitSimCLI do
  let(:cli) { described_class.new }

  describe '#simulate' do
    before do
      # Mock renderers
      allow(OrbitSim::Renderer::Terminal).to receive(:new).and_return(double(run: nil))
      allow(OrbitSim::Renderer::Graphic).to receive(:new).and_return(double(run: nil, speed: nil, render: nil, export_png: nil, collect_frame: nil, export_gif: nil))
    end

    context 'with preset' do
      let(:preset_bodies) do
        [OrbitSim::Body.new(mass: 1e20, position: Vector[0,0,0], velocity: Vector[0,0,0])]
      end

      before do
        allow(OrbitSim::Presets).to receive(:load).with('solar_system').and_return(preset_bodies)
      end

      it 'runs simulation with terminal renderer by default' do
        expect(OrbitSim::Renderer::Terminal).to receive(:new)
        cli.simulate('solar_system')
      end

      it 'runs simulation with graphic renderer when specified' do
        skip "Graphic renderer not available" unless defined?(OrbitSim::Renderer::Graphic)
        expect(OrbitSim::Renderer::Graphic).to receive(:new)
        cli.invoke(:simulate, ['solar_system'], { mode: 'graphic' })
      end

      it 'exports PNG when requested' do
        graphic_renderer = double('graphic_renderer')
        allow(OrbitSim::Renderer::Graphic).to receive(:new).and_return(graphic_renderer)
        expect(graphic_renderer).to receive(:export_png).with('solar_system.png')
        cli.invoke(:simulate, ['solar_system'], { mode: 'graphic', export: 'png' })
      end

      it 'exports GIF when requested' do
        graphic_renderer = double('graphic_renderer')
        allow(OrbitSim::Renderer::Graphic).to receive(:new).and_return(graphic_renderer)
        expect(graphic_renderer).to receive(:collect_frame).exactly(100).times
        expect(graphic_renderer).to receive(:export_gif).with('solar_system.gif')
        cli.invoke(:simulate, ['solar_system'], { mode: 'graphic', export: 'gif', frames: 100 })
      end
    end

    context 'with load option' do
      let(:mock_simulation) { double('simulation') }

      before do
        allow(OrbitSim::Simulation).to receive(:from_json).with('test.json').and_return(mock_simulation)
      end

      it 'loads simulation from file' do
        expect(OrbitSim::Simulation).to receive(:from_json).with('test.json')
        cli.invoke(:simulate, [], { load: 'test.json' })
      end
    end

    context 'without preset or load' do
      it 'raises error' do
        expect { cli.simulate }.to raise_error('Either PRESET or --load must be provided')
      end
    end

    context 'saving simulation' do
      let(:mock_simulation) { double('simulation', to_json: nil) }

      before do
        allow(OrbitSim::Presets).to receive(:load).and_return([OrbitSim::Body.new(mass: 1, position: Vector[0,0,0], velocity: Vector[0,0,0])])
        allow(OrbitSim::Renderer::Terminal).to receive(:new).and_return(double(run: nil))
        allow(OrbitSim::Simulation).to receive(:new).and_return(mock_simulation)
      end

      it 'saves simulation when save option is provided' do
        expect(mock_simulation).to receive(:to_json).with('output.json')
        cli.invoke(:simulate, ['preset'], { save: 'output.json' })
      end
    end
  end

  describe '#list' do
    it 'lists available presets' do
      presets = ['solar_system', 'earth_moon']
      allow(OrbitSim::Presets).to receive(:list).and_return(presets)
      expect { cli.list }.to output("solar_system\nearth_moon\n").to_stdout
    end
  end

  describe '#version' do
    it 'shows version' do
      expect { cli.version }.to output("#{OrbitSim::VERSION}\n").to_stdout
    end
  end
end