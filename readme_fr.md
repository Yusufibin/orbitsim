# HelioSim

**Le simulateur d'orbites le plus beau et le plus éducatif jamais fait en Ruby.**

[![Gem Version](https://badge.fury.io/rb/orbitsim.svg)](https://badge.fury.io/rb/orbitsim)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Un simulateur physique réaliste de mouvements orbitaux (N-Body) écrit en Ruby pur. Exécutez-le dans votre terminal ou avec une interface graphique.

![HelioSim Demo](visuals/demo.gif)

## Installation

```bash
gem install orbitsim
```

Ou avec Bundler :

```ruby
gem 'orbitsim', '~> 0.1.0'
```

Puis `bundle install`.

## Utilisation

### Ligne de commande

```bash
# Lister les presets disponibles
orbitsim list

# Lancer une simulation (mode terminal par défaut)
orbitsim simulate solar_system

# Lancer avec le preset Trappist-1
orbitsim simulate trappist_1

# Mode graphique
orbitsim simulate solar_system --mode graphic

# Vitesse x10
orbitsim simulate solar_system --speed 10

# Exporter en PNG (mode graphic)
orbitsim simulate solar_system --mode graphic --export png

# Exporter en GIF animé
orbitsim simulate solar_system --mode terminal --export gif --frames 100

# Sauvegarder la simulation
orbitsim simulate solar_system --save my_simulation.json

# Charger une simulation sauvegardée
orbitsim simulate --load my_simulation.json
```

### En Ruby

```ruby
require 'orbitsim'

# Charger un preset
preset = OrbitSim::Presets.load('solar_system')
simulation = OrbitSim::Simulation.new(preset)

# Créer une simulation personnalisée
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

# Step par step
simulation.step

# Obtenir les données de rendu
data = simulation.render_data

# Sauvegarder/charger
simulation.to_json('my_simulation.json')
simulation = OrbitSim::Simulation.from_json('my_simulation.json')
```

## Presets disponibles

| Preset | Description |
|--------|-------------|
| `solar_system` | Système solaire complet (Soleil + 8 planètes) |
| `trappist_1` | Système Trappist-1 avec ses 7 planètes |
| `earth_moon` | Système Terre-Lune simplifié |
| `binary_system` | Système binaire d'étoiles |

## Contrôles (mode terminal)

| Touche | Action |
|--------|--------|
| `p` / `espace` | Pause / Reprendre |
| `1` | Vitesse x1 |
| `2` | Vitesse x10 |
| `3` | Vitesse x100 |
| `+` / `-` | Zoom avant / arrière |
| `f` | Suivre le corps suivant |
| `c` | Centrer la vue |
| `t` | Afficher/cacher les trajets |
| `q` | Quitter |



## Structure du projet

```
helio-sim/
├── bin/
│   └── orbitsim              # Exécutable CLI
├── lib/
│   ├── orbitsim.rb
│   └── orbitsim/
│       ├── body.rb           # Classe corps céleste
│       ├── simulation.rb     # Moteur de simulation N-Body
│       ├── presets.rb        # Chargement des presets
│       ├── version.rb
│       ├── renderer/
│       │   ├── terminal.rb   # Rendu terminal ANSI
│       │   └── graphic.rb    # Rendu graphique ruby2d
│       └── presets/
│           ├── solar_system.json
│           ├── trappist_1.json
│           ├── earth_moon.json
│           └── binary_system.json
├── spec/                     # Tests RSpec
├── coverage/                # Couverture de tests
└── orbitsim.gemspec
```

## Développement

```bash
# Cloner le repository
git clone https://github.com/yusufibin/helio-sim.git
cd helio-sim

# Installer les dépendances
bundle install

# Exécuter les tests
bundle exec rspec

# Lancer le simulateur
bundle exec bin/orbitsim simulate solar_system --mode terminal
```

## Exigences

- Ruby 3.3+
- Gems utilisées :
  - `thor` - CLI
  - `rmagick` - Export d'images (optionnel)
  - `rspec` - Tests
  - `matrix` - Calculs vectoriels

## License

MIT License - voir [LICENSE](LICENSE)