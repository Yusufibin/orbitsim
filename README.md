# Orbitsim

**The most beautiful and educational orbit simulator ever made in Ruby.**

[![Gem Version](https://badge.fury.io/rb/orbitsim.svg)](https://badge.fury.io/rb/orbitsim)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A realistic physical simulator of orbital movements (N-Body) written in pure Ruby. Run it in your terminal or with a graphical interface.



## Installation

```bash
gem install orbitsim
```

Or with Bundler:

```ruby
gem 'orbitsim', '~> 0.1.0'
```

Then `bundle install`.

## Usage

### Command Line

```bash
# List available presets
orbitsim list

# Launch a simulation (terminal mode by default)
orbitsim simulate solar_system

# Launch with Trappist-1 preset
orbitsim simulate trappist_1

# Graphic mode
orbitsim simulate solar_system --mode graphic

# Speed x10
orbitsim simulate solar_system --speed 10

# Export to PNG (graphic mode)
orbitsim simulate solar_system --mode graphic --export png

# Export to animated GIF
orbitsim simulate solar_system --mode terminal --export gif --frames 100

# Save simulation
orbitsim simulate solar_system --save my_simulation.json

# Load saved simulation
orbitsim simulate --load my_simulation.json
```

### In Ruby

```ruby
require 'orbitsim'

# Load a preset
preset = OrbitSim::Presets.load('solar_system')
simulation = OrbitSim::Simulation.new(preset)

# Create a custom simulation
sun = OrbitSim::Body.new(
  mass: 1.989e30,
  position: Vector[0, 0, 0],
  velocity: Vector[0, 0, 0],
  name: 'Sun',
  radius: 6.96e8
)

earth = OrbitSim::Body.new(
  mass: 5.972e24,
  position: Vector[1.496e11, 0, 0],
  velocity: Vector[0, 2.978e4, 0],
  name: 'Earth',
  radius: 6.371e6
)

simulation = OrbitSim::Simulation.new([sun, earth])

# Step by step
simulation.step

# Get render data
data = simulation.render_data

# Save/load
simulation.to_json('my_simulation.json')
simulation = OrbitSim::Simulation.from_json('my_simulation.json')
```

## Available Presets

| Preset | Description |
|--------|-------------|
| `solar_system` | Complete solar system (Sun + 8 planets) |
| `trappist_1` | Trappist-1 system with its 7 planets |
| `earth_moon` | Simplified Earth-Moon system |
| `binary_system` | Binary star system |

## Controls (terminal mode)

| Key | Action |
|-----|--------|
| `p` / `space` | Pause / Resume |
| `1` | Speed x1 |
| `2` | Speed x10 |
| `3` | Speed x100 |
| `+` / `-` | Zoom in / out |
| `f` | Follow next body |
| `c` | Center view |
| `t` | Show/hide trails |
| `q` | Quit |



## Project Structure

```
helio-sim/
├── bin/
│   └── orbitsim              # CLI executable
├── lib/
│   ├── orbitsim.rb
│   └── orbitsim/
│       ├── body.rb           # Celestial body class
│       ├── simulation.rb     # N-Body simulation engine
│       ├── presets.rb        # Preset loading
│       ├── version.rb
│       ├── renderer/
│       │   ├── terminal.rb   # ANSI terminal rendering
│       │   └── graphic.rb    # ruby2d graphic rendering
│       └── presets/
│           ├── solar_system.json
│           ├── trappist_1.json
│           ├── earth_moon.json
│           └── binary_system.json
├── spec/                     # RSpec tests
├── coverage/                 # Test coverage
└── orbitsim.gemspec
```

## Development

```bash
# Clone the repository
git clone https://github.com/yusufibin/helio-sim.git
cd helio-sim

# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Launch the simulator
bundle exec bin/orbitsim simulate solar_system --mode terminal
```

## Requirements

- Ruby 3.3+
- Gems used:
  - `thor` - CLI
  - `rmagick` - Image export (optional)
  - `rspec` - Tests
  - `matrix` - Vector calculations

## License

MIT License - see [LICENSE](LICENSE)

