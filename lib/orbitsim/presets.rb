require 'json'

module OrbitSim
  module Presets
    PRESETS_DIR = File.expand_path('presets', __dir__)

    def self.list
      Dir.glob("#{PRESETS_DIR}/*.json").map { |f| File.basename(f, '.json') }
    end

    def self.load(name)
      file = "#{PRESETS_DIR}/#{name}.json"
      if File.exist?(file)
        data = JSON.parse(File.read(file))
        data.map do |body_data|
          Body.new(
            mass: body_data['mass'],
            position: Vector[*body_data['position']],
            velocity: Vector[*body_data['velocity']],
            color: body_data['color'] || 'white',
            radius: body_data['radius'] || 1,
            name: body_data['name'] || ''
          )
        end
      else
        raise "Preset #{name} not found"
      end
    end
  end
end