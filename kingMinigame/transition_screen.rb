# final_stats_screen.rb
class FinalStatsScreen
  def initialize(stats:, perfect:)
    @stats = stats
    @perfect = perfect

    @texts = []
    @shapes = []

    @alpha = 0.0
    @selected_index = 0

    build_ui
  end

  # ─────────────────────────────────────────────
  # UI BUILD
  # ─────────────────────────────────────────────
  def build_ui
    @texts << Text.new(
      @perfect ? "PERFECT RUN!" : "FINAL RESULTS",
      x: 260,
      y: 40,
      size: 34,
      color: @perfect ? 'green' : 'yellow'
    )

    y_left = 120
    y_right = 120
    index = 0

    @stats.each do |game, data|
      game_name = game.gsub(/([a-z])([A-Z])/, '\1 \2')

      # LEFT SIDE (game names)
      @texts << Text.new(
        game_name,
        x: 80,
        y: y_left,
        size: 22,
        color: 'white'
      )

      # RIGHT SIDE (summary)
      summary_color = data[:wins] == data[:attempts] ? 'green' : 'white'

      @texts << Text.new(
        "Wins: #{data[:wins]} / #{data[:attempts]}",
        x: 350,
        y: y_right,
        size: 20,
        color: summary_color
      )

      # Fail details
      (data[:failures] || []).each do |f|
        @texts << Text.new(
          "L#{f[:level]}: #{f[:reason]}",
          x: 380,
          y: y_right + 20,
          size: 14,
          color: 'red'
        )
        y_right += 18
      end

      # spacing per game
      y_left += 70
      y_right = y_left

      index += 1
    end

    @texts << Text.new(
      "Press ENTER to restart",
      x: 240,
      y: 540,
      size: 18,
      color: 'gray'
    )

    # PERFECT RUN BADGE
    if @perfect
      @badge = Text.new(
        "🏆 PERFECT!",
        x: 320,
        y: 80,
        size: 28,
        color: 'yellow'
      )
      @texts << @badge
    end

    # BACKGROUND CONFETTI (simple)
    25.times do
      @shapes << Square.new(
        x: rand(800),
        y: rand(600),
        size: rand(4..8),
        color: ['red', 'blue', 'yellow', 'green'].sample
      )
    end
  end

  # ─────────────────────────────────────────────
  # INPUT
  # ─────────────────────────────────────────────
  def handle_input(event)
    return :restart if event.key == 'return'
  end

  # ─────────────────────────────────────────────
  # UPDATE (animation)
  # ─────────────────────────────────────────────
  def update
    @alpha = [@alpha + 0.03, 1].min

    @texts.each do |t|
      t.opacity = @alpha if t.respond_to?(:opacity=)
    end

    @shapes.each do |s|
      s.y += 0.3
      s.x += Math.sin(Time.now.to_f * 2) * 0.2
    end
  end

  # ─────────────────────────────────────────────
  # CLEANUP
  # ─────────────────────────────────────────────
  def cleanup
    @texts.each(&:remove)
    @shapes.each(&:remove)
  end
end
