# ui/hearts.rb
# Draws 3 heart icons in the top-right corner.
# Hearts are always visible during gameplay; call update(lives) to redraw.

class Hearts
  HEART_SIZE   = 28
  HEART_SPACING = 36
  MARGIN_X     = 720
  MARGIN_Y     = 12

  # A heart is drawn as two overlapping circles + a rotated square (diamond base)
  # Ruby2D doesn't have a native polygon, so we approximate with circles + rectangle.

  def initialize(lives)
    @lives   = lives
    @objects = []
    draw
  end

  def update(lives)
    @lives = lives
    @objects.each(&:remove)
    @objects.clear
    draw
  end

  def remove
    @objects.each(&:remove)
    @objects.clear
  end

  private

  def draw
    3.times do |i|
      x_center = MARGIN_X + i * HEART_SPACING
      y_center = MARGIN_Y + HEART_SIZE / 2

      if i < @lives
        color = 'red'
      else
        color = [0.3, 0.3, 0.3, 0.6]   # dark grey = lost life (Ruby2D RGBA array)
      end

      # Two circles for the top lobes of the heart
      @objects << Circle.new(
        x: x_center - 7, y: y_center - 4,
        radius: 9,
        color: color
      )
      @objects << Circle.new(
        x: x_center + 7, y: y_center - 4,
        radius: 9,
        color: color
      )

      # Triangle-ish bottom: a rotated square sitting below the circles
      @objects << Square.new(
        x: x_center - 9, y: y_center - 2,
        size: 13,
        color: color
      )
    end
  end
end
