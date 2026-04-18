require_relative "lib/orbitsim/version"

Gem::Specification.new do |spec|
  spec.name          = "orbitsim"
  spec.version       = OrbitSim::VERSION
  spec.authors       = ["Youssouf"]
  spec.email         = ["youssouf@example.com"]

  spec.summary       = %q{A beautiful, educational N-body orbital simulator written in pure Ruby.}
  spec.description   = %q{Simulate realistic orbital mechanics with an N-body physics engine. Run in terminal or with graphical interface. Educational and extensible.}
  spec.homepage      = "https://github.com/youssouf/helio-sim"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/youssouf/helio-sim"
  spec.metadata["changelog_uri"] = "https://github.com/youssouf/helio-sim/blob/main/CHANGELOG.md"

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "rmagick", "~> 5.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_development_dependency "chunky_png"
end