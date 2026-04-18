require 'io/console'

begin
  require 'rmagick'
rescue LoadError
  puts "rmagick gem not installed. Install with: gem install rmagick"
end

module OrbitSim
  module Renderer
    class Terminal
      ANSI_COLORS = {
        reset: "\e[0m",
        red: "\e[31m",
        green: "\e[32m",
        yellow: "\e[33m",
        blue: "\e[34m",
        magenta: "\e[35m",
        cyan: "\e[36m",
        white: "\e[37m",
        bold: "\e[1m",
        dim: "\e[2m"
      }

      BODY_SYMBOLS = {
        'star' => '☀',
        'planet' => '●',
        'moon' => '○',
        'comet' => '✶',
        'dwarf' => '⊕'
      }

      def initialize(simulation)
        @simulation = simulation
        @paused = false
        @speed = 1
        @zoom = 1.0
        @follow_body = nil
        @running = true
        @frames = []
        @trails = {}
        @show_trails = true
        @trail_length = 50
      end

      def run
        setup_terminal
        loop do
          break unless @running
          handle_input
          unless @paused
            @simulation.step
            update_trails
          end
          render
          sleep(@simulation.dt / @speed) if @speed > 0 && !@paused
        end
        restore_terminal
      end

      private

      def setup_terminal
        print "\e[?25l"
        IO.console&.raw!
        @width = [60, IO.console&.winsize&.first.to_i - 1].compact.max
        @height = [20, IO.console&.winsize&.last.to_i - 10].compact.max
      end

      def restore_terminal
        print "\e[?25h"
        IO.console&.cooked!
        puts "\e[0m"
      end

      def handle_input
        return unless IO.console
        input = IO.console.read_nonblock(1) rescue nil
        case input
        when 'p', ' '
          @paused = !@paused
        when '1'
          @speed = 1
        when '2'
          @speed = 10
        when '3'
          @speed = 100
        when '+', '='
          @zoom *= 1.5
        when '-', '_'
          @zoom /= 1.5
        when 'f'
          @follow_body = (@follow_body.nil? ? 0 : (@follow_body + 1) % @simulation.bodies.size)
        when 'c'
          @follow_body = nil
        when 't'
          @show_trails = !@show_trails
        when 'q', "\e"
          @running = false
        end
      end

      def update_trails
        @simulation.bodies.each_with_index do |body, i|
          @trails[i] ||= []
          @trails[i] << body.position.dup
          @trails[i] = @trails[i].last(@trail_length)
        end
      end

      def render(capture = false)
        output = render_to_string
        if capture
          output
        else
          print "\e[2J\e[H"
          print output
          nil
        end
      end

      def render_to_string
        left_panel = render_simulation_view
        right_panel = render_info_panel
        combined = merge_panels(left_panel, right_panel)
        header + combined + footer
      end

      def render_simulation_view
        width = @width || 60
        height = @height || 20
        grid = Array.new(height) { Array.new(width, ' ') }

        center_x = width / 2
        center_y = height / 2

        all_positions = @simulation.bodies.map(&:position)
        min_bound = Vector[*all_positions.map { |p| p.min }.to_a]
        max_bound = Vector[*all_positions.map { |p| p.max }.to_a]

        if @follow_body
          view_center = @simulation.bodies[@follow_body].position
        else
          view_center = Vector[0, 0, 0]
        end

        range = max_bound - min_bound
        max_range = [range.max, 1e10].max
        scale = max_range / [height, width].min * 2 / @zoom

        if @show_trails
          @simulation.bodies.each_with_index do |body, i|
            trail = @trails[i] || []
            trail.each do |pos|
              x = pos[0] - view_center[0]
              y = pos[1] - view_center[1]
              grid_x = center_x + (x / scale).round
              grid_y = center_y - (y / scale).round
              if grid_x.between?(0, width - 1) && grid_y.between?(0, height - 1)
                grid[grid_y][grid_x] = "#{ANSI_COLORS[:dim]}·#{ANSI_COLORS[:reset]}"
              end
            end
          end
        end

        @simulation.bodies.each_with_index do |body, i|
          x = body.position[0] - view_center[0]
          y = body.position[1] - view_center[1]
          grid_x = center_x + (x / scale).round
          grid_y = center_y - (y / scale).round

          symbol = case i
                   when 0 then "#{ANSI_COLORS[:yellow]}☀#{ANSI_COLORS[:reset]}"
                   when 1 then "#{ANSI_COLORS[:cyan]}●#{ANSI_COLORS[:reset]}"
                   when 2 then "#{ANSI_COLORS[:white]}○#{ANSI_COLORS[:reset]}"
                   else "#{ANSI_COLORS[:green]}⊕#{ANSI_COLORS[:reset]}"
                   end

          if grid_x.between?(0, width - 1) && grid_y.between?(0, height - 1)
            grid[grid_y][grid_x] = symbol
          end
        end

        if @follow_body
          if center_x.between?(0, width - 1) && center_y.between?(0, height - 1)
            grid[center_y][center_x] = "#{ANSI_COLORS[:magenta]}+#{ANSI_COLORS[:reset]}"
          end
        end

        result = []
        result << "┌#{'─' * width}┐"
        grid.each do |row|
          result << "│#{row.join}│"
        end
        result << "└#{'─' * width}┘"
        result.join("\n")
      end

      def render_info_panel
        lines = []

        lines << "#{ANSI_COLORS[:bold]}#{ANSI_COLORS[:cyan]}╔══════════════════════════════╗#{ANSI_COLORS[:reset]}"
        lines << "#{ANSI_COLORS[:bold]}#{ANSI_COLORS[:cyan]}║      HELIOSIM - ORBITAL       ║#{ANSI_COLORS[:reset]}"
        lines << "#{ANSI_COLORS[:bold]}#{ANSI_COLORS[:cyan]}╚══════════════════════════════╝#{ANSI_COLORS[:reset]}"

        status = @paused ? "#{ANSI_COLORS[:red]}PAUSED#{ANSI_COLORS[:reset]}" : "#{ANSI_COLORS[:green]}RUNNING#{ANSI_COLORS[:reset]}"
        lines << "  #{status} | Speed: x#{@speed} | Zoom: #{'%.1f' % @zoom}"

        t = @simulation.time || 0
        days = (t / 86400).to_i
        years = (days / 365.25).to_f
        lines << "  Time: #{days}d #{'%.2f' % (t/3600 % 24)}h (#{'%.3f' % years} years)"

        lines << ""
        lines << "#{ANSI_COLORS[:bold]}Celestial Bodies:#{ANSI_COLORS[:reset]}"

        @simulation.bodies.each_with_index do |body, i|
          prefix = i == @follow_body ? "#{ANSI_COLORS[:magenta]}▶#{ANSI_COLORS[:reset]}" : " "
          name_color = i == 0 ? ANSI_COLORS[:yellow] : ANSI_COLORS[:white]
          lines << "#{prefix} #{name_color}#{body.name}#{ANSI_COLORS[:reset]}"

          dist = body.position.magnitude
          dist_au = dist / 1.496e11
          vel = body.velocity.magnitude / 1000

          lines << "   ├ dist: #{dist_au < 0.01 ? '%.4f AU' % dist_au : '%.3f AU' % dist_au}"
          lines << "   ├ vel:  #{'%.2f' % vel} km/s"
          lines << "   └ mass: #{'%.2e' % body.mass} kg"
        end

        lines << ""
        lines << "#{ANSI_COLORS[:bold]}Energy:#{ANSI_COLORS[:reset]}"
        ke = @simulation.kinetic_energy / 1e30
        pe = @simulation.potential_energy / 1e30
        te = @simulation.total_energy / 1e30
        lines << "  Kinetic:    #{'%.3e' % ke} J"
        lines << "  Potential:  #{'%.3e' % pe} J"
        lines << "  Total:      #{'%.3e' % te} J"

        while lines.count < (@height || 20) - 3
          lines << ""
        end

        lines.join("\n")
      end

      def merge_panels(left, right)
        left_lines = left.split("\n")
        right_lines = right.split("\n")

        width = @width || 60
        height = @height || 20
        max_height = [left_lines.count, right_lines.count, height].max
        result = []

        max_height.times do |i|
          left_part = left_lines[i] || " " * (width + 2)
          right_part = right_lines[i] || ""
          result << left_part + " " + right_part
        end

        result.join("\n")
      end

      def header
        "\e[1;1H\e[2J\e[H#{ANSI_COLORS[:blue]}─── HelioSim N-Body Orbital Simulator ───#{ANSI_COLORS[:reset]}\n"
      end

      def footer
        "\n#{ANSI_COLORS[:dim]}Controls: #{ANSI_COLORS[:reset]}p/space: pause | 1/2/3: speed | +/-: zoom | f: follow | t: trails | q: quit#{ANSI_COLORS[:reset]}"
      end

      def collect_frame
        @frames << render_to_string
      end

      def export_gif(filename)
        return unless defined?(Magick)
        return if @frames.empty?

        images = Magick::ImageList.new
        @frames.each do |frame_text|
          img = Magick::Image.new(900, 600) do |i|
            i.background_color = 'black'
            i.pointsize = 11
            i.font_family = 'Courier'
            i.fill = 'white'
          end
          draw = Magick::Draw.new
          draw.annotate(img, 0, 0, 10, 20, frame_text)
          images << img
        end
        images.delay = 5
        images.write(filename)
      end
    end
  end
end
