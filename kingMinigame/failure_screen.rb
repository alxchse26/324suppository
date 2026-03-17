# screens/failure_screen.rb
# Shown when the player runs out of lives.

class FailureScreen
  def initialize
    @objects = []
    draw
  end

  def handle_input(event)
    return unless event.is_a?(Ruby2D::KeyEvent)
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
      color: [0.18, 0.0, 0.0, 0.92]
    )

    @objects << Text.new(
      '💀  GAME OVER  💀',
      x: 195, y: 155,
      size: 54,
      color: 'red'
    )

    @objects << Text.new(
      'You ran out of lives.',
      x: 275, y: 260,
      size: 28,
      color: 'white'
    )

    @objects << Text.new(
      'Better luck next time...',
      x: 255, y: 305,
      size: 24,
      color: [1.0, 0.6, 0.6, 1]
    )

    @objects << Text.new(
      'Press ENTER to try again',
      x: 245, y: 400,
      size: 24,
      color: [1, 0.8, 0.2, 1]
    )
  end
end
