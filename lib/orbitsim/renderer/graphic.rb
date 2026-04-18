begin
  require 'ruby2d'
rescue LoadError
  puts "ruby2d gem not installed. Install with: gem install ruby2d"
  exit 1
end

begin
  require 'chunky_png'
rescue LoadError
  puts "chunky_png gem not installed. Install with: gem install chunky_png"
end

begin
  require 'rmagick'
rescue LoadError
  puts "rmagick gem not installed. Install with: gem install rmagick"
end

module OrbitSim
  module Renderer
    class Graphic
      attr_accessor :zoom, :offset_x, :offset_y, :speed, :paused, :selected_body

      def initialize(simulation)
        @simulation = simulation
        @original_dt = @simulation.dt
        @window = Ruby2D::Window.new(title: "OrbitSim", width: 800, height: 600)
        @zoom = 1e-9  # Scale factor (meters to pixels)
        @offset_x = 400  # Center x
        @offset_y = 300  # Center y
        @speed = 1.0    # Simulation speed multiplier
        @paused = false
        @selected_body = nil
        @trajectories = {}  # body => array of [world_x, world_y] positions
        @starfield = generate_starfield(200)  # 200 stars
        @frames = []  # For GIF export

        setup_event_handlers
        initialize_trajectories
      end

      def speed=(value)
        @speed = value
        @simulation.dt = @original_dt / @speed
      end

      def run
        @window.show
        @window.update do
          unless @paused
            @simulation.step
            update_trajectories
          end
          render
        end
      end

      def render
        @window.clear

        # Draw starfield
        @starfield.each do |star|
          Ruby2D::Circle.new(
            x: star[:x],
            y: star[:y],
            radius: star[:size],
            color: star[:color]
          )
        end

        # Draw trajectories
        @trajectories.each do |body, positions|
          next if positions.size < 2
          screen_positions = positions.map { |wx, wy| world_to_screen(wx, wy) }
          screen_positions.each_cons(2) do |(x1, y1), (x2, y2)|
            Ruby2D::Line.new(
              x1: x1, y1: y1, x2: x2, y2: y2,
              width: 1,
              color: body.color
            )
          end
        end

        # Draw bodies
        @simulation.bodies.each do |body|
          x, y = world_to_screen(body.position[0], body.position[1])
          radius = [body.radius * @zoom * 100, 2].max  # Scale radius, minimum 2px

          circle = Ruby2D::Circle.new(
            x: x,
            y: y,
            radius: radius,
            color: body.color
          )

          # Highlight selected body
          if body == @selected_body
            Ruby2D::Circle.new(
              x: x,
              y: y,
              radius: radius + 3,
              color: 'white',
              z: 1
            )
          end
        end

        # Draw info panel for selected body
        if @selected_body
          draw_info_panel
        end
      end

      def export_png(filename)
        return unless defined?(ChunkyPNG)
        image = ChunkyPNG::Image.new(@window.width, @window.height, ChunkyPNG::Color::BLACK)

        # Draw starfield
        @starfield.each do |star|
          color = parse_color(star[:color])
          (-star[:size]..star[:size]).each do |dx|
            (-star[:size]..star[:size]).each do |dy|
              dist = Math.sqrt(dx**2 + dy**2)
              next if dist > star[:size]
              px = (star[:x] + dx).to_i
              py = (star[:y] + dy).to_i
              next if px < 0 || px >= @window.width || py < 0 || py >= @window.height
              image[px, py] = color
            end
          end
        end

        # Draw trajectories
        @trajectories.each do |body, positions|
          next if positions.size < 2
          color = parse_color(body.color)
          positions.each_cons(2) do |(x1, y1), (x2, y2)|
            # Simple line drawing (Bresenham's algorithm approximation)
            dx = (x2 - x1).abs
            dy = (y2 - y1).abs
            sx = x1 < x2 ? 1 : -1
            sy = y1 < y2 ? 1 : -1
            err = dx - dy

            x, y = x1.to_i, y1.to_i
            while x != x2.to_i || y != y2.to_i
              if x >= 0 && x < @window.width && y >= 0 && y < @window.height
                image[x, y] = color
              end
              e2 = 2 * err
              if e2 > -dy
                err -= dy
                x += sx
              end
              if e2 < dx
                err += dx
                y += sy
              end
            end
          end
        end

        # Draw bodies
        @simulation.bodies.each do |body|
          x, y = world_to_screen(body.position[0], body.position[1])
          radius = [body.radius * @zoom * 100, 2].max
          color = parse_color(body.color)

          # Draw circle (simple filled circle approximation)
          (-radius..radius).each do |dx|
            (-radius..radius).each do |dy|
              dist = Math.sqrt(dx**2 + dy**2)
              next if dist > radius
              px = (x + dx).to_i
              py = (y + dy).to_i
              next if px < 0 || px >= @window.width || py < 0 || py >= @window.height
              image[px, py] = color
            end
          end

          # Highlight selected body
          if body == @selected_body
            highlight_color = ChunkyPNG::Color::WHITE
            (-(radius + 3)..(radius + 3)).each do |dx|
              (-(radius + 3)..(radius + 3)).each do |dy|
                dist = Math.sqrt(dx**2 + dy**2)
                next unless dist.between?(radius, radius + 3)
                px = (x + dx).to_i
                py = (y + dy).to_i
                next if px < 0 || px >= @window.width || py < 0 || py >= @window.height
                image[px, py] = highlight_color
              end
            end
          end
        end

        image.save(filename)
      end

      def collect_frame
        return unless defined?(ChunkyPNG)
        image = ChunkyPNG::Image.new(@window.width, @window.height, ChunkyPNG::Color::BLACK)

        # Draw starfield
        @starfield.each do |star|
          color = parse_color(star[:color])
          (-star[:size]..star[:size]).each do |dx|
            (-star[:size]..star[:size]).each do |dy|
              dist = Math.sqrt(dx**2 + dy**2)
              next if dist > star[:size]
              px = (star[:x] + dx).to_i
              py = (star[:y] + dy).to_i
              next if px < 0 || px >= @window.width || py < 0 || py >= @window.height
              image[px, py] = color
            end
          end
        end

        # Draw trajectories
        @trajectories.each do |body, positions|
          next if positions.size < 2
          color = parse_color(body.color)
          positions.each_cons(2) do |(x1, y1), (x2, y2)|
            # Simple line drawing (Bresenham's algorithm approximation)
            dx = (x2 - x1).abs
            dy = (y2 - y1).abs
            sx = x1 < x2 ? 1 : -1
            sy = y1 < y2 ? 1 : -1
            err = dx - dy

            x, y = x1.to_i, y1.to_i
            while x != x2.to_i || y != y2.to_i
              if x >= 0 && x < @window.width && y >= 0 && y < @window.height
                image[x, y] = color
              end
              e2 = 2 * err
              if e2 > -dy
                err -= dy
                x += sx
              end
              if e2 < dx
                err += dx
                y += sy
              end
            end
          end
        end

        # Draw bodies
        @simulation.bodies.each do |body|
          x, y = world_to_screen(body.position[0], body.position[1])
          radius = [body.radius * @zoom * 100, 2].max
          color = parse_color(body.color)

          # Draw circle (simple filled circle approximation)
          (-radius..radius).each do |dx|
            (-radius..radius).each do |dy|
              dist = Math.sqrt(dx**2 + dy**2)
              next if dist > radius
              px = (x + dx).to_i
              py = (y + dy).to_i
              next if px < 0 || px >= @window.width || py < 0 || py >= @window.height
              image[px, py] = color
            end
          end

          # Highlight selected body
          if body == @selected_body
            highlight_color = ChunkyPNG::Color::WHITE
            (-(radius + 3)..(radius + 3)).each do |dx|
              (-(radius + 3)..(radius + 3)).each do |dy|
                dist = Math.sqrt(dx**2 + dy**2)
                next unless dist.between?(radius, radius + 3)
                px = (x + dx).to_i
                py = (y + dy).to_i
                next if px < 0 || px >= @window.width || py < 0 || py >= @window.height
                image[px, py] = highlight_color
              end
            end
          end
        end

        @frames << image.to_blob
      end

      def export_gif(filename)
        return unless defined?(Magick)
        return if @frames.empty?

        images = Magick::ImageList.new
        @frames.each do |blob|
          img = Magick::Image.from_blob(blob).first
          images << img
        end
        images.delay = 10  # 10/100ths second delay between frames
        images.write(filename)
      end

      private

      def setup_event_handlers
        @window.on :key_down do |event|
          case event.key
          when 'space'
            @paused = !@paused
          when 'r'
            @zoom = 1e-9
            @offset_x = 400
            @offset_y = 300
          when '+', '='
            @zoom *= 1.2
          when '-'
            @zoom /= 1.2
          when 'up'
            @offset_y -= 20
          when 'down'
            @offset_y += 20
          when 'left'
            @offset_x -= 20
          when 'right'
            @offset_x += 20
          when '1'
            @speed = 0.1
          when '2'
            @speed = 1.0
          when '3'
            @speed = 10.0
          when '4'
            @speed = 100.0
          when 'p'
            export_png("orbitsim_#{Time.now.strftime('%Y%m%d_%H%M%S')}.png")
          end
        end

        @window.on :mouse_down do |event|
          @selected_body = find_body_at(event.x, event.y)
        end

        @window.on :mouse_scroll do |event|
          if event.delta_y > 0
            @zoom *= 1.1
          else
            @zoom /= 1.1
          end
        end
      end

      def world_to_screen(world_x, world_y)
        screen_x = world_x * @zoom + @offset_x
        screen_y = world_y * @zoom + @offset_y
        [screen_x, screen_y]
      end

      def screen_to_world(screen_x, screen_y)
        world_x = (screen_x - @offset_x) / @zoom
        world_y = (screen_y - @offset_y) / @zoom
        [world_x, world_y]
      end

      def find_body_at(screen_x, screen_y)
        world_x, world_y = screen_to_world(screen_x, screen_y)
        @simulation.bodies.find do |body|
          dx = body.position[0] - world_x
          dy = body.position[1] - world_y
          Math.sqrt(dx**2 + dy**2) <= body.radius
        end
      end

      def initialize_trajectories
        @simulation.bodies.each do |body|
          @trajectories[body] = [[body.position[0], body.position[1]]]
        end
      end

      def update_trajectories
        @simulation.bodies.each do |body|
          @trajectories[body] << [body.position[0], body.position[1]]
          # Limit trajectory length to prevent memory issues
          @trajectories[body].shift if @trajectories[body].size > 1000
        end
      end

      def generate_starfield(count)
        stars = []
        count.times do
          stars << {
            x: rand(@window.width),
            y: rand(@window.height),
            size: rand(1..3),
            color: ['white', 'lightgray', 'gray'].sample
          }
        end
        stars
      end

      def draw_info_panel
        panel_x = 10
        panel_y = 10
        panel_width = 200
        panel_height = 120

        # Background
        Ruby2D::Rectangle.new(
          x: panel_x,
          y: panel_y,
          width: panel_width,
          height: panel_height,
          color: 'rgba(0, 0, 0, 0.8)'
        )

        # Border
        Ruby2D::Rectangle.new(
          x: panel_x,
          y: panel_y,
          width: panel_width,
          height: panel_height,
          color: 'white'
        )

        # Text
        Ruby2D::Text.new(
          "#{@selected_body.name}",
          x: panel_x + 10,
          y: panel_y + 10,
          size: 16,
          color: 'white'
        )

        Ruby2D::Text.new(
          "Mass: #{@selected_body.mass.to_science_notation}",
          x: panel_x + 10,
          y: panel_y + 35,
          size: 12,
          color: 'white'
        )

        Ruby2D::Text.new(
          "Position: (#{@selected_body.position[0].to_science_notation}, #{@selected_body.position[1].to_science_notation})",
          x: panel_x + 10,
          y: panel_y + 55,
          size: 12,
          color: 'white'
        )

        Ruby2D::Text.new(
          "Velocity: (#{@selected_body.velocity[0].to_science_notation}, #{@selected_body.velocity[1].to_science_notation})",
          x: panel_x + 10,
          y: panel_y + 75,
          size: 12,
          color: 'white'
        )

        Ruby2D::Text.new(
          "Radius: #{@selected_body.radius}",
          x: panel_x + 10,
          y: panel_y + 95,
          size: 12,
          color: 'white'
        )
      end

      def parse_color(color_name)
        # Simple color mapping for PNG export
        colors = {
          'white' => ChunkyPNG::Color::WHITE,
          'black' => ChunkyPNG::Color::BLACK,
          'red' => ChunkyPNG::Color::RED,
          'green' => ChunkyPNG::Color::GREEN,
          'blue' => ChunkyPNG::Color::BLUE,
          'yellow' => ChunkyPNG::Color::YELLOW,
          'cyan' => ChunkyPNG::Color::CYAN,
          'magenta' => ChunkyPNG::Color::MAGENTA,
          'gray' => ChunkyPNG::Color::GRAY,
          'lightgray' => ChunkyPNG::Color::LIGHTGRAY
        }
        colors[color_name] || ChunkyPNG::Color::WHITE
      end
    end
  end
end

# Monkey patch Float for scientific notation
class Float
  def to_science_notation
    sprintf("%.2e", self)
  end
end