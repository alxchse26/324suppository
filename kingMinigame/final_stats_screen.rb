# final_stats_screen.rb
class FinalStatsScreen
  def initialize(stats:, perfect:)
    @texts = []

    y = 500

    title = perfect ? "PERFECT RUN! 🎉" : "Final Stats"
    @texts << Text.new(title, x: 250, y: y, size: 40, color: 'yellow')
    y -= 60

    stats.each do |game, data|
      summary = "#{game}: #{data[:wins]}/#{data[:attempts]}"
      @texts << Text.new(summary, x: 100, y: y, size: 25, color: 'white')
      y -= 30

      data[:failures].each do |fail|
        detail = "Level #{fail[:level]}: #{fail[:reason]}"
        @texts << Text.new(detail, x: 120, y: y, size: 18, color: 'red')
        y -= 25
      end

      y -= 20
    end
    
    if perfect
      20.times do
        Square.new(
          x: rand(800),
          y: rand(600),
          size: 5,
          color: ['red', 'blue', 'green', 'yellow'].sample
        )
      end
    end

    @texts << Text.new("Press ENTER to restart", x: 200, y: 50, size: 20)
  end

  def handle_input(event)
    return :restart if event.key == 'return'
  end

  def cleanup
    @texts.each(&:remove)
  end
end
