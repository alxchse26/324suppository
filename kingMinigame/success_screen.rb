# screens/success_screen.rb
# Shown when the player clears all 5 levels.

class SuccessScreen
  def initialize
    @objects = []
    draw
  end

  def handle_input(event)
    return :restart if event.key == 'return' || event.key == 'enter'
    nil
  end

  def cleanup
    @objects.each(&:remove)
    @objects.clear
  end

  private

  def draw
    @objects << Rectangle.new(
      x: 0, y: 0, width: 800, height: 600,
      color: [0.0, 0.15, 0.0, 0.92]
    )

    @objects << Text.new(
      '🏆  YOU WIN!  🏆',
      x: 210, y: 160,
      size: 56,
      color: 'gold'
    )

    @objects << Text.new(
      'All 5 levels conquered.',
      x: 255, y: 260,
      size: 28,
      color: 'white'
    )

    @objects << Text.new(
      'You are a true speed-clicker.',
      x: 220, y: 305,
      size: 24,
      color: [0.7, 1.0, 0.7, 1]
    )

    @objects << Text.new(
      'Press ENTER to play again',
      x: 250, y: 400,
      size: 24,
      color: 'lime'
    )
  end
end
