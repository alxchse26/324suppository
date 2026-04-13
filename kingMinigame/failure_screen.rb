# failure_screen.rb
# Shown when the player runs out of lives.
# Accepts lives: keyword (always 0 at game over) and draws empty hearts.

class FailureScreen

  BUTTON_X = 300
  BUTTON_Y = 430
  BUTTON_W = 200
  BUTTON_H = 50

  def initialize(lives: 0)
    @lives   = lives    # will be 0, but kept as param for consistency
    @objects = []
    draw
  end

  def handle_input(event)
    # Keyboard: ENTER restarts
    if event.respond_to?(:key)
      return :restart if event.key == 'return' || event.key == 'enter'
    end

    # Mouse: click anywhere inside the restart button
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
    # Dark red background
    @objects << Rectangle.new(
      x: 0, y: 0, width: 800, height: 600,
      color: [0.14, 0.0, 0.0, 1.0]
    )

    # GAME OVER text
    @objects << Text.new(
      'GAME OVER',
      x: 170, y: 100,
      size: 90,
      color: 'red'
    )

    # Subtitle
    @objects << Text.new(
      'You ran out of lives.',
      x: 270, y: 220,
      size: 26,
      color: [1.0, 0.6, 0.6, 1]
    )

    # "Lives remaining:" label
    @objects << Text.new(
      'Lives remaining:',
      x: 200, y: 285,
      size: 20,
      color: [0.7, 0.7, 0.7, 1]
    )

    # Draw 3 empty (grey) hearts — lives is always 0 here
    draw_hearts

    # Divider
    @objects << Line.new(
      x1: 100, y1: 390, x2: 700, y2: 390,
      width: 1, color: [0.4, 0.1, 0.1, 0.8]
    )

    # Restart button
    @objects << Rectangle.new(
      x: BUTTON_X, y: BUTTON_Y,
      width: BUTTON_W, height: BUTTON_H,
      color: [0.6, 0.1, 0.1, 1.0]
    )
    # Button border
    @objects << Rectangle.new(
      x: BUTTON_X - 2, y: BUTTON_Y - 2,
      width: BUTTON_W + 4, height: BUTTON_H + 4,
      color: [1.0, 0.3, 0.3, 0.8]
    )
    @objects << Rectangle.new(
      x: BUTTON_X, y: BUTTON_Y,
      width: BUTTON_W, height: BUTTON_H,
      color: [0.6, 0.1, 0.1, 1.0]
    )
    @objects << Text.new(
      'RESTART',
      x: BUTTON_X + 42, y: BUTTON_Y + 12,
      size: 26,
      color: 'white'
    )

    # ENTER hint below button
    @objects << Text.new(
      'or press ENTER',
      x: 330, y: 492,
      size: 16,
      color: [0.6, 0.4, 0.4, 1]
    )
  end

  def draw_hearts
    start_x = 400
    spacing = 48

    # Center 3 hearts around x=400
    offsets = [-spacing, 0, spacing]
    offsets.each do |dx|
      cx = start_x + dx
      cy = 330
      # All grey — no lives remain
      color = [0.25, 0.25, 0.25, 0.6]
      @objects << Circle.new(x: cx - 9,  y: cy - 5, radius: 11, color: color)
      @objects << Circle.new(x: cx + 9,  y: cy - 5, radius: 11, color: color)
      @objects << Square.new(x: cx - 11, y: cy - 2, size: 16,   color: color)
    end
  end

end
