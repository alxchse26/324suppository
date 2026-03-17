# screens/start_screen.rb
# Shown when the game first launches.
# Renders title, subtitle, and a "Press ENTER to Play" prompt.
# Cleaned up the moment the player presses ENTER.

class StartScreen
  def initialize
    @objects = []
    draw
  end

  def handle_input(event)
    return unless event.is_a?(Ruby2D::KeyEvent)
    if event.key == 'return' || event.key == 'enter'
      return :start_game
    end
    nil
  end

  def cleanup
    @objects.each(&:remove)
    @objects.clear
  end

  private

  def draw
    # Dark gradient-ish background panel
    @objects << Rectangle.new(
      x: 150, y: 160,
      width: 500, height: 280,
      color: [0.05, 0.05, 0.2, 0.85]
    )

    # Border
    @objects << Rectangle.new(x: 148, y: 158, width: 504, height: 284, color: [0.4, 0.4, 1, 0.5])
    @objects << Rectangle.new(x: 150, y: 160, width: 500, height: 280, color: [0.05, 0.05, 0.2, 0.85])

    @objects << Text.new(
      '✈  MINI GAMES  ✈',
      x: 210, y: 200,
      size: 48,
      color: 'white'
    )

    @objects << Text.new(
      'A series of rapid-fire challenges',
      x: 230, y: 270,
      size: 22,
      color: [0.7, 0.8, 1, 1]
    )

    @objects << Text.new(
      '3 lives  ·  5 levels  ·  escalating difficulty',
      x: 195, y: 305,
      size: 18,
      color: [0.6, 0.7, 0.9, 1]
    )

    # Pulsing prompt (static — Ruby2D doesn't do CSS animations, but we keep it simple)
    @objects << Text.new(
      'Press  ENTER  to begin',
      x: 265, y: 370,
      size: 22,
      color: 'lime'
    )
  end
end
