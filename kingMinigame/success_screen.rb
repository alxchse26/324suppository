# success_screen.rb
# Shown when the player clears all 5 levels.
# Accepts lives: so it can display how many hearts the player finished with.

class SuccessScreen

  BUTTON_X = 300
  BUTTON_Y = 460
  BUTTON_W = 200
  BUTTON_H = 50

  def initialize(lives: 3)
    @lives   = lives
    @objects = []
    draw
  end

  def handle_input(event)
    # Keyboard: ENTER restarts
    if event.respond_to?(:key)
      return :restart if event.key == 'return' || event.key == 'enter'
    end

    # Mouse: click inside restart button
    if event.respond_to?(:button) && event.button == :left
      if event.x.between?(BUTTON_X, BUTTON_X + BUTTON_W) &&
         event.y.between?(BUTTON_Y, BUTTON_Y + BUTTON_H)
        return :restart
      end
    end

    nil
  end

  def cleanup
    @objects.each(&:remove)
    @objects.clear
  end

  private

  def draw
    # Dark green background
    @objects << Rectangle.new(
      x: 0, y: 0, width: 800, height: 600,
      color: [0.0, 0.10, 0.03, 1.0]
    )

    # YOU WIN! text
    @objects << Text.new(
      'YOU WIN!',
      x: 165, y: 80,
      size: 110,
      color: 'gold'
    )

    # Subtitle
    @objects << Text.new(
      'All 5 levels conquered. Incredible!',
      x: 185, y: 215,
      size: 24,
      color: [0.7, 1.0, 0.7, 1]
    )

    # Lives remaining label
    lives_text = @lives == 1 ? '1 life remaining' : "#{@lives} lives remaining"
    @objects << Text.new(
      lives_text,
      x: 290, y: 268,
      size: 22,
      color: 'white'
    )

    # Draw hearts showing remaining lives
    draw_hearts

    # Divider
    @objects << Line.new(
      x1: 100, y1: 420, x2: 700, y2: 420,
      width: 1, color: [0.2, 0.5, 0.2, 0.8]
    )

    # Restart button
    @objects << Rectangle.new(
      x: BUTTON_X - 2, y: BUTTON_Y - 2,
      width: BUTTON_W + 4, height: BUTTON_H + 4,
      color: [0.3, 0.8, 0.3, 0.8]
    )
    @objects << Rectangle.new(
      x: BUTTON_X, y: BUTTON_Y,
      width: BUTTON_W, height: BUTTON_H,
      color: [0.05, 0.4, 0.1, 1.0]
    )
    @objects << Text.new(
      'PLAY AGAIN',
      x: BUTTON_X + 22, y: BUTTON_Y + 12,
      size: 26,
      color: 'white'
    )

    # ENTER hint
    @objects << Text.new(
      'or press ENTER',
      x: 330, y: 522,
      size: 16,
      color: [0.4, 0.6, 0.4, 1]
    )
  end

  def draw_hearts
    start_x = 400
    spacing = 56

    # Center 3 hearts
    offsets = [-spacing, 0, spacing]
    offsets.each_with_index do |dx, i|
      cx = start_x + dx
      cy = 370
      # Red if the player still has this life, grey if spent
      color = i < @lives ? [1.0, 0.15, 0.15, 1.0] : [0.25, 0.25, 0.25, 0.45]
      @objects << Circle.new(x: cx - 9,  y: cy - 5, radius: 11, color: color)
      @objects << Circle.new(x: cx + 9,  y: cy - 5, radius: 11, color: color)
      @objects << Square.new(x: cx - 11, y: cy - 2, size: 16,   color: color)
    end
  end

end
