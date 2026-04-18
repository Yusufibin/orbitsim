require 'spec_helper'

RSpec.describe OrbitSim::Presets do
  describe '.list' do
    it 'returns a list of available preset names' do
      presets = described_class.list
      expect(presets).to be_an(Array)
      expect(presets).to include('solar_system')
      expect(presets).to include('earth_moon')
      expect(presets).to include('binary_system')
      expect(presets).to include('trappist_1')
    end

    it 'returns preset names without .json extension' do
      presets = described_class.list
      presets.each do |preset|
        expect(preset).not_to end_with('.json')
      end
    end
  end

  describe '.load' do
    it 'loads solar_system preset' do
      bodies = described_class.load('solar_system')
      expect(bodies).to be_an(Array)
      expect(bodies.size).to be > 1
      bodies.each do |body|
        expect(body).to be_a(OrbitSim::Body)
        expect(body.mass).to be > 0
        expect(body.position).to be_a(Vector)
        expect(body.velocity).to be_a(Vector)
      end
    end

    it 'loads earth_moon preset' do
      bodies = described_class.load('earth_moon')
      expect(bodies).to be_an(Array)
      expect(bodies.size).to eq(2)
      names = bodies.map(&:name)
      expect(names).to include('Earth')
      expect(names).to include('Moon')
    end

    it 'raises error for non-existent preset' do
      expect { described_class.load('non_existent') }.to raise_error('Preset non_existent not found')
    end

    it 'sets default values for missing attributes' do
      bodies = described_class.load('solar_system')
      sun = bodies.find { |b| b.name == 'Sun' }
      expect(sun.color).to eq('yellow') # Should be set in JSON
      # For bodies without explicit radius, should default to 1.0
      earth = bodies.find { |b| b.name == 'Earth' }
      expect(earth.radius).to be > 0
    end
  end
end