# final_stats_screen.rb
class FinalStatsScreen
  def initialize(stats:, perfect:)
    @stats   = stats
    @perfect = perfect
    @texts   = []
    @shapes  = []
    @alpha   = 0.0
    build_ui
  end

  def build_ui
    # Dark background
    @shapes << Rectangle.new(
      x: 0, y: 0, width: 800, height: 600,
      color: [0.05, 0.05, 0.05, 1.0], z: 0
    )

    # Confetti — drawn at z=1 so it's behind text
    100.times do
      @shapes << Square.new(
        x: rand(800),
        y: rand(600),
        size: rand(4..10),
        color: ['red', 'blue', 'yellow', 'green', 'orange', 'purple', 'white'].sample,
        z: 1
      )
    end

    # "YOU WON" above everything
    @texts << Text.new(
      'YOU WON!',
      x: 290, y: 10,
      size: 36, color: 'green', z: 10
    )

    # FINAL RESULTS or PERFECT RUN title
    @texts << Text.new(
      @perfect ? 'PERFECT RUN!' : 'FINAL RESULTS',
      x: 240, y: 55,
      size: 34,
      color: @perfect ? 'lime' : 'yellow',
      z: 10
    )

    # Divider
    @shapes << Line.new(
      x1: 40, y1: 108, x2: 760, y2: 108,
      width: 1, color: [0.4, 0.4, 0.4, 0.8], z: 10
    )

    # Column headers
    @texts << Text.new('Game',         x: 60,  y: 116, size: 15, color: [0.8, 0.8, 0.8, 1], z: 10)
    @texts << Text.new('Wins',         x: 360, y: 116, size: 15, color: [0.8, 0.8, 0.8, 1], z: 10)
    @texts << Text.new('Failed Levels',x: 500, y: 116, size: 15, color: [0.8, 0.8, 0.8, 1], z: 10)

    y = 148
    @stats.each do |game_key, data|
      name     = game_key.to_s.gsub(/([A-Z])/, ' \1').strip
      wins     = data[:wins]     || 0
      attempts = data[:attempts] || 0
      failures = data[:failures] || []

      # Game name
      @texts << Text.new(name, x: 60, y: y, size: 18, color: 'white', z: 10)

      # Wins
      win_color = wins == attempts && attempts > 0 ? 'lime' : [1.0, 0.6, 0.6, 1]
      @texts << Text.new("#{wins} / #{attempts}", x: 360, y: y, size: 18, color: win_color, z: 10)

      # Failed levels
      if failures.empty?
        @texts << Text.new('none', x: 500, y: y, size: 18, color: 'lime', z: 10)
      else
        failed_str = failures.map { |f| "L#{f[:level]}: #{f[:reason]}" }.join('  ')
        @texts << Text.new(failed_str, x: 500, y: y, size: 13, color: 'red', z: 10)
      end

      y += 60
    end

    # Divider above prompt
    @shapes << Line.new(
      x1: 40, y1: 530, x2: 760, y2: 530,
      width: 1, color: [0.4, 0.4, 0.4, 0.8], z: 10
    )

    # Press ENTER prompt
    @texts << Text.new(
      'Press ENTER to restart',
      x: 270, y: 548,
      size: 18, color: 'gray', z: 10
    )

    # Perfect badge
    if @perfect
      @texts << Text.new(
        '★ PERFECT RUN! ★',
        x: 270, y: 580,
        size: 16, color: [1.0, 0.84, 0.0, 1.0], z: 10
      )
    end
  end

  def handle_input(event)
    return :restart if event.respond_to?(:key) && 
                       (event.key == 'return' || event.key == 'enter')
    nil
  end

  def update(dt = nil)
    # Animate confetti falling and drifting
    @shapes.each do |s|
      next unless s.is_a?(Square)
      s.y += 0.6
      s.x += Math.sin(Time.now.to_f + s.y * 0.05) * 0.4
      # Wrap confetti back to top when it falls off screen
      s.y = rand(-20..0) if s.y > 610
    end
  end

  def cleanup
    @texts.each(&:remove)
    @shapes.each(&:remove)
  end
end
